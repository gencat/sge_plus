# frozen_string_literal: true

module Decidim
  module Candidacies
    class Menu
      def self.register_menu!
        Decidim.menu :menu do |menu|
          menu.add_item :candidacies,
                        I18n.t("menu.candidacies", scope: "decidim"),
                        decidim_candidacies.candidacies_path,
                        position: 2.4,
                        active: %r{^/(candidacies|create_candidacy)},
                        if: Decidim::CandidacysType.joins(:scopes).where(organization: current_organization).any?
        end
      end

      def self.register_mobile_menu!
        Decidim.menu :mobile_menu do |menu|
          menu.add_item :candidacies,
                        I18n.t("menu.candidacies", scope: "decidim"),
                        decidim_candidacies.candidacies_path,
                        position: 2.4,
                        active: %r{^/(candidacies|create_candidacy)},
                        if: !Decidim::CandidacysType.joins(:scopes).where(organization: current_organization).all.empty?
        end
      end

      def self.register_home_content_block_menu!
        Decidim.menu :home_content_block_menu do |menu|
          menu.add_item :candidacies,
                        I18n.t("menu.candidacies", scope: "decidim"),
                        decidim_candidacies.candidacies_path,
                        position: 30,
                        active: :inclusive,
                        if: Decidim::CandidacysType.joins(:scopes).where(organization: current_organization).any?
        end
      end

      def self.register_admin_menu_modules!
        Decidim.menu :admin_menu_modules do |menu|
          menu.add_item :candidacies,
                        I18n.t("menu.candidacies", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacies_path,
                        icon_name: "lightbulb-flash-line",
                        position: 2.4,
                        active: is_active_link?(decidim_admin_candidacies.candidacies_path) ||
                                is_active_link?(decidim_admin_candidacies.candidacies_types_path) ||
                                is_active_link?(
                                  decidim_admin_candidacies.edit_candidacies_setting_path(
                                    Decidim::CandidacysSettings.find_or_create_by!(organization: current_organization)
                                  )
                                ),
                        if: allowed_to?(:enter, :space_area, space_name: :candidacies)
        end
      end

      def self.register_admin_candidacies_components_menu!
        Decidim.menu :admin_candidacies_components_menu do |menu|
          current_participatory_space.components.each do |component|
            caption = decidim_escape_translated(component.name)
            caption += content_tag(:span, component.primary_stat, class: "component-counter") if component.primary_stat.present?

            menu.add_item [component.manifest_name, component.id].join("_"),
                          caption.html_safe,
                          manage_component_path(component),
                          active: is_active_link?(manage_component_path(component)) ||
                                  is_active_link?(decidim_admin_candidacies.edit_component_path(current_participatory_space, component)) ||
                                  is_active_link?(decidim_admin_candidacies.edit_component_permissions_path(current_participatory_space, component)) ||
                                  is_active_link?(decidim_admin_candidacies.component_share_tokens_path(current_participatory_space, component)) ||
                                  participatory_space_active_link?(component),
                          if: component.manifest.admin_engine # && user_role_config.component_is_accessible?(component.manifest_name)
          end
        end
      end

      def self.register_admin_candidacy_menu!
        Decidim.menu :admin_candidacy_menu do |menu|
          menu.add_item :edit_candidacy,
                        I18n.t("menu.information", scope: "decidim.admin"),
                        decidim_admin_candidacies.edit_candidacy_path(current_participatory_space),
                        icon_name: "information-line",
                        if: allowed_to?(:edit, :candidacy, candidacy: current_participatory_space)

          menu.add_item :candidacy_committee_requests,
                        I18n.t("menu.committee_members", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacy_committee_requests_path(current_participatory_space),
                        icon_name: "group-line",
                        if: current_participatory_space.promoting_committee_enabled? && allowed_to?(:manage_membership, :candidacy,
                                                                                                    candidacy: current_participatory_space)

          menu.add_item :components,
                        I18n.t("menu.components", scope: "decidim.admin"),
                        decidim_admin_candidacies.components_path(current_participatory_space),
                        icon_name: "tools-line",
                        active: is_active_link?(decidim_admin_candidacies.components_path(current_participatory_space),
                                                ["decidim/candidacies/admin/components", %w(index new edit)]),
                        if: allowed_to?(:read, :component, candidacy: current_participatory_space),
                        submenu: { target_menu: :admin_candidacies_components_menu }
          menu.add_item :candidacy_attachments,
                        I18n.t("menu.attachments", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacy_attachments_path(current_participatory_space),
                        icon_name: "attachment-2",
                        if: allowed_to?(:read, :attachment, candidacy: current_participatory_space)

          menu.add_item :moderations,
                        I18n.t("menu.moderations", scope: "decidim.admin"),
                        decidim_admin_candidacies.moderations_path(current_participatory_space),
                        icon_name: "flag-line",
                        if: allowed_to?(:read, :moderation)

          menu.add_item :candidacies_share_tokens,
                        I18n.t("menu.share_tokens", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacy_share_tokens_path(current_participatory_space),
                        active: is_active_link?(decidim_admin_candidacies.candidacy_share_tokens_path(current_participatory_space)),
                        icon_name: "share-line",
                        if: allowed_to?(:read, :share_tokens, current_participatory_space:)
        end
      end

      def self.register_admin_candidacy_actions_menu!
        Decidim.menu :admin_candidacy_actions_menu do |menu|
          menu.add_item :answer_candidacy,
                        I18n.t("actions.answer", scope: "decidim.candidacies"),
                        decidim_admin_candidacies.edit_candidacy_answer_path(current_participatory_space),
                        if: allowed_to?(:answer, :candidacy, candidacy: current_participatory_space)

          menu.add_item :candidacy_permissions,
                        I18n.t("actions.permissions", scope: "decidim.admin"),
                        decidim_admin_candidacies.edit_candidacy_permissions_path(current_participatory_space, resource_name: :candidacy),
                        if: current_participatory_space.allow_resource_permissions? && allowed_to?(:update, :candidacy, candidacy: current_participatory_space)
        end
      end

      def self.register_admin_candidacies_menu!
        Decidim.menu :admin_candidacies_menu do |menu|
          menu.add_item :candidacies,
                        I18n.t("menu.candidacies", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacies_path,
                        position: 1,
                        icon_name: "lightbulb-flash-line",
                        active: is_active_link?(decidim_admin_candidacies.candidacies_path),
                        if: allowed_to?(:index, :candidacy)

          menu.add_item :candidacies_types,
                        I18n.t("menu.candidacies_types", scope: "decidim.admin"),
                        decidim_admin_candidacies.candidacies_types_path,
                        position: 2,
                        icon_name: "layout-masonry-line",
                        active: is_active_link?(decidim_admin_candidacies.candidacies_types_path),
                        if: allowed_to?(:manage, :candidacy_type)

          menu.add_item :candidacies_settings,
                        I18n.t("menu.candidacies_settings", scope: "decidim.admin"),
                        decidim_admin_candidacies.edit_candidacies_setting_path(
                          Decidim::CandidacysSettings.find_or_create_by!(
                            organization: current_organization
                          )
                        ),
                        position: 3,
                        icon_name: "tools-line",
                        active: is_active_link?(
                          decidim_admin_candidacies.edit_candidacies_setting_path(
                            Decidim::CandidacysSettings.find_or_create_by!(organization: current_organization)
                          )
                        ),
                        if: allowed_to?(:update, :candidacies_settings)
        end
      end
    end
  end
end
