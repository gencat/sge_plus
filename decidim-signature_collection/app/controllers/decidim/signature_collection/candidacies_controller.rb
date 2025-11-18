# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This controller contains the logic regarding participants candidacies
    class CandidaciesController < Decidim::SignatureCollection::ApplicationController
      include ParticipatorySpaceContext

      helper Decidim::AttachmentsHelper
      helper Decidim::FiltersHelper
      helper Decidim::OrdersHelper
      helper Decidim::ResourceHelper
      helper Decidim::IconHelper
      helper Decidim::Comments::CommentsHelper
      helper Decidim::Admin::IconLinkHelper
      helper Decidim::ResourceReferenceHelper
      helper PaginateHelper
      helper CandidacyHelper
      helper SignatureTypeOptionsHelper
      helper Decidim::ActionAuthorizationHelper

      include CandidacySlug
      include FilterResource
      include Paginable
      include Decidim::FormFactory
      include Decidim::SignatureCollection::Orderable
      include TypeSelectorOptions
      include NeedsCandidacy
      include SingleCandidacyType
      include Decidim::IconHelper

      helper_method :collection, :candidacies, :filter, :stats, :tabs, :panels
      helper_method :candidacy_type, :available_candidacy_types

      before_action :authorize_participatory_space, only: [:show]
      before_action :set_candidacies_settings, only: [:index, :show, :edit]

      # GET /candidacies
      def index
        enforce_permission_to :list, :candidacy
        return unless search.result.blank? && params.dig("filter", "with_any_state") != %w(closed)

        @closed_candidacies ||= search_with(filter_params.merge(with_any_state: %w(closed)))

        if @closed_candidacies.result.present?
          params[:filter] ||= {}
          params[:filter][:with_any_state] = %w(closed)
          @forced_closed_candidacies = true

          @search = @closed_candidacies
        end
      end

      # GET /candidacies/:id
      def show
        enforce_permission_to :read, :candidacy, candidacy: current_candidacy

        if current_candidacy.type.published?
          render layout: "decidim/candidacy_head"
        else
          flash[:alert] = I18n.t("decidim.signature_collection.show.type_not_published")
          redirect_to candidacies_path
        end
      end

      # GET /candidacies/:id/send_to_technical_validation
      def send_to_technical_validation
        enforce_permission_to :send_to_technical_validation, :candidacy, candidacy: current_candidacy

        SendCandidacyToTechnicalValidation.call(current_candidacy, current_user) do
          on(:ok) do
            redirect_to EngineRouter.main_proxy(current_candidacy).candidacies_path(candidacy_slug: nil), flash: {
              notice: I18n.t(
                "success",
                scope: "decidim.signature_collection.admin.candidacies.edit"
              )
            }
          end
        end
      end

      # GET /candidacies/:slug/edit
      def edit
        enforce_permission_to :edit, :candidacy, candidacy: current_candidacy
        form_attachment_model = form(AttachmentForm).from_model(current_candidacy.attachments.first)
        @form = form(Decidim::SignatureCollection::CandidacyForm)
                .from_model(
                  current_candidacy,
                  candidacy: current_candidacy
                )
        @form.attachment = form_attachment_model
      end

      # PUT /candidacies/:id
      def update
        enforce_permission_to :update, :candidacy, candidacy: current_candidacy

        params[:id] = params[:slug]
        params[:type_id] = current_candidacy.type&.id
        @form = form(Decidim::SignatureCollection::CandidacyForm)
                .from_params(params, candidacy_type: current_candidacy.type, candidacy: current_candidacy)

        UpdateCandidacy.call(current_candidacy, @form) do
          on(:ok) do |candidacy|
            flash[:notice] = I18n.t("success", scope: "decidim.signature_collection.update")
            redirect_to candidacy_path(candidacy)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("error", scope: "decidim.signature_collection.update")
            render :edit, layout: "decidim/candidacy"
          end
        end
      end

      def print
        enforce_permission_to :print, :candidacy, candidacy: current_candidacy
        output = Decidim::SignatureCollection::ApplicationFormPDF.new(current_candidacy).render
        send_data(output, filename: "candidacy_submit_#{current_candidacy.id}.pdf", type: "application/pdf")
      end

      private

      alias current_candidacy current_participatory_space

      def current_participatory_space
        return unless params["slug"]

        @current_participatory_space ||= Candidacy.find(id_from_slug(params[:slug]))
      end

      def current_participatory_space_manifest
        @current_participatory_space_manifest ||= Decidim.find_participatory_space_manifest(:candidacies)
      end

      def candidacies
        @candidacies = search.result.includes(:scoped_type)
        @candidacies = reorder(@candidacies)
        @candidacies = paginate(@candidacies)
      end

      alias collection candidacies

      def search_collection
        Candidacy
          .includes(scoped_type: [:scope])
          .joins("JOIN decidim_users ON decidim_users.id = decidim_signature_collection_candidacies.decidim_author_id")
          .joins(scoped_type: :type)
          .where(organization: current_organization)
          .where(decidim_signature_collection_candidacies_types: { published: true })
      end

      def default_filter_params
        {
          search_text_cont: "",
          with_any_state: %w(open),
          with_any_type: nil,
          author: "any",
          with_any_scope: nil,
          with_any_area: nil
        }
      end

      def stats
        @stats ||= CandidacyStatsPresenter.new(candidacy: current_candidacy)
      end

      def tabs
        @tabs ||= items.map { |item| item.slice(:id, :text, :icon) }
      end

      def panels
        @panels ||= items.map { |item| item.slice(:id, :method, :args) }
      end

      def items
        @items ||= [
          {
            enabled: @current_candidacy.documents.present?,
            id: "documents",
            text: t("decidim.application.documents.documents"),
            icon: resource_type_icon_key("documents"),
            method: :cell,
            args: ["decidim/documents_panel", @current_candidacy]
          }
        ].select { |item| item[:enabled] }
      end

      def set_candidacies_settings
        @candidacies_settings ||= Decidim::SignatureCollection::CandidaciesSettings.find_by(organization: current_organization)
      end
    end
  end
end
