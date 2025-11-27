# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module SignatureCollection
    module ExportSignatures
      extend ActiveSupport::Concern

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
            send_data(output, filename: "signatures_#{current_candidacy.id}.pdf", type: "application/pdf")
          end
        end
      end

      def export_xml_signatures
        enforce_permission_to :export_xml_signatures, :candidacy, candidacy: current_candidacy

        require "zip"

        id_dir = Rails.root.join("storage", "xml_signatures", current_candidacy.id.to_s)
        slug_dir = Rails.root.join("storage", "xml_signatures", current_candidacy.slug.to_s)
        candidacy_dir = [id_dir, slug_dir].find { |dir| Dir.exist?(dir) }
        return render(plain: I18n.t("decidim.signature_collection.export.xml.directory_missing"), status: :not_found) if candidacy_dir.blank?

        xml_files = Dir.glob(File.join(candidacy_dir, "*.xml"))
        return render(plain: I18n.t("decidim.signature_collection.export.xml.no_files"), status: :not_found) if xml_files.empty?

        zip_io = StringIO.new
        Zip::OutputStream.write_buffer(zip_io) do |zos|
          xml_files.each do |file_path|
            entry_name = File.basename(file_path)
            zos.put_next_entry(entry_name)
            zos.write File.binread(file_path)
          end
        end
        zip_io.rewind

        respond_to do |format|
          format.any { send_data zip_io.read, filename: "signatures_#{current_candidacy.id}.zip", type: "application/zip" }
        end
      end

      private

      def pdf_signature_service
        @pdf_signature_service ||= Decidim.pdf_signature_service.to_s.safe_constantize
      end
    end
  end
end
