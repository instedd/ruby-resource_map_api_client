module ResourceMap
  class ImportWizard
    def initialize(collection)
      @collection = collection
    end

    attr_reader :collection
    delegate :api, to: :collection

    def url
      api.url "collections/#{collection.id}/import_wizard"
    end

    def upload(file)
      api.post "collections/#{collection.id}/import_wizard/upload_csv", file: file
    end

    def guess_columns_spec
      api.json "collections/#{collection.id}/import_wizard/guess_columns_spec"
    end

    def validate_sites_with_columns(columns_spec)
      api.json_post "collections/#{collection.id}/import_wizard/validate_sites_with_columns", columns: columns_spec.to_json
    end

    def is_column_spec_valid?(columns_spec)
      validation = validate_sites_with_columns(columns_spec)

      validation['errors'].values.all? { |v| v.nil? || v.empty? }
    end

    def status
      api.json("collections/#{collection.id}/import_wizard/job_status")['status']
    end

    def execute(columns_spec)
      h = Hash.new
      columns_spec.each_with_index do |c, i|
        h[i.to_s] = c
      end
      api.post "collections/#{collection.id}/import_wizard/execute", columns: h
    end
  end
end
