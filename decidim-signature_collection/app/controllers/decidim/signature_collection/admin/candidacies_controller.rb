# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      require "csv"

      # Controller used to manage the candidacies
      class CandidaciesController < Decidim::SignatureCollection::Admin::ApplicationController
        include Decidim::SignatureCollection::NeedsCandidacy
        include Decidim::SignatureCollection::SingleCandidacyType
        include Decidim::SignatureCollection::TypeSelectorOptions
        include Decidim::SignatureCollection::Admin::Filterable
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        helper ::Decidim::Admin::ResourcePermissionsHelper
        helper Decidim::SignatureCollection::CandidacyHelper
        helper Decidim::SignatureCollection::SignatureTypeOptionsHelper

        helper_method :show_candidacy_type_callout?

        # GET /admin/candidacies
        def index
          enforce_permission_to :list, :candidacy
          @candidacies = filtered_collection
        end

        # GET /admin/candidacies/:id/edit
        def edit
          enforce_permission_to :edit, :candidacy, candidacy: current_candidacy

          form_attachment_model = form(AttachmentForm).from_model(current_candidacy.attachments.first)
          @form = form(Decidim::SignatureCollection::Admin::CandidacyForm)
                  .from_model(
                    current_candidacy,
                    candidacy: current_candidacy
                  )
          @form.attachment = form_attachment_model

          render layout: "decidim/admin/candidacy"
        end

        # PUT /admin/candidacies/:id
        def update
          enforce_permission_to :update, :candidacy, candidacy: current_candidacy

          params[:id] = params[:slug]
          @form = form(Decidim::SignatureCollection::Admin::CandidacyForm)
                  .from_params(params, candidacy: current_candidacy)

          Decidim::SignatureCollection::Admin::UpdateCandidacy.call(@form, current_candidacy) do
            on(:ok) do |candidacy|
              flash[:notice] = I18n.t("candidacies.update.success", scope: "decidim.signature_collection.admin")
              redirect_to edit_candidacy_path(candidacy)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("candidacies.update.error", scope: "decidim.signature_collection.admin")
              render :edit, layout: "decidim/admin/signature_collection/candidacy"
            end
          end
        end

        # POST /admin/candidacies/:id/publish
        def publish
          enforce_permission_to :publish, :candidacy, candidacy: current_candidacy

          PublishCandidacy.call(current_candidacy, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.publish.success", scope: "decidim.signature_collection.admin")
              redirect_to decidim_admin_candidacies.edit_candidacy_path(current_candidacy)
            end
          end
        end

        # DELETE /admin/candidacies/:id/unpublish
        def unpublish
          enforce_permission_to :unpublish, :candidacy, candidacy: current_candidacy

          UnpublishCandidacy.call(current_candidacy, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.unpublish.success", scope: "decidim.signature_collection.admin")
              redirect_to decidim_admin_candidacies.edit_candidacy_path(current_candidacy)
            end
          end
        end

        # DELETE /admin/candidacies/:id/discard
        def discard
          enforce_permission_to :discard, :candidacy, candidacy: current_candidacy
          DiscardCandidacy.call(current_candidacy, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.discard.success", scope: "decidim.signature_collection.admin")
              redirect_to decidim_admin_candidacies.edit_candidacy_path(current_candidacy)
            end
          end
        end

        # POST /admin/candidacies/:id/accept
        def accept
          enforce_permission_to :accept, :candidacy, candidacy: current_candidacy
          AcceptCandidacy.call(current_candidacy, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.accept.success", scope: "decidim.signature_collection.admin")
              redirect_to decidim_admin_candidacies.edit_candidacy_path(current_candidacy)
            end
          end
        end

        # DELETE /admin/candidacies/:id/reject
        def reject
          enforce_permission_to :reject, :candidacy, candidacy: current_candidacy
          RejectCandidacy.call(current_candidacy, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.reject.success", scope: "decidim.signature_collection.admin")
              redirect_to decidim_admin_candidacies.edit_candidacy_path(current_candidacy)
            end
          end
        end

        # GET /admin/candidacies/:id/send_to_technical_validation
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

        # GET /admin/candidacies/export
        def export
          enforce_permission_to :export, :candidacies

          Decidim::SignatureCollection::ExportCandidaciesJob.perform_later(
            current_user,
            current_organization,
            params[:format] || default_format,
            params[:collection_ids].presence&.map(&:to_i)
          )

          flash[:notice] = t("decidim.admin.exports.notice")

          redirect_back(fallback_location: candidacies_path)
        end

        # GET /admin/candidacies/:id/export_votes
        def export_votes
          enforce_permission_to :export_votes, :candidacy, candidacy: current_candidacy

          votes = current_candidacy.votes.map(&:sha1)
          csv_data = CSV.generate(headers: false) do |csv|
            votes.each do |sha1|
              csv << [sha1]
            end
          end

          respond_to do |format|
            format.csv { send_data csv_data, file_name: "votes.csv" }
          end
        end

        # GET /admin/candidacies/:id/export_pdf_signatures.pdf
        def export_pdf_signatures
          enforce_permission_to :export_pdf_signatures, :candidacy, candidacy: current_candidacy

          @votes = current_candidacy.votes

          serializer = Decidim::Forms::UserAnswersSerializer
          pdf_export = Decidim::Exporters::CandidacyVotesPDF.new(@votes, current_candidacy, serializer).export

          output = if pdf_signature_service
                     pdf_signature_service.new(pdf: pdf_export.read).signed_pdf
                   else
                     pdf_export.read
                   end

          respond_to do |format|
            format.pdf do
              send_data(output, filename: "votes_#{current_candidacy.id}.pdf", type: "application/pdf")
            end
          end
        end

        private

        def show_candidacy_type_callout?
          Decidim::SignatureCollection::CandidaciesType.where(organization: current_organization).none?
        end

        def collection
          @collection ||= ManageableCandidacies.for(current_user)
        end

        def pdf_signature_service
          @pdf_signature_service ||= Decidim.pdf_signature_service.to_s.safe_constantize
        end

        def default_format
          "json"
        end
      end
    end
  end
end
