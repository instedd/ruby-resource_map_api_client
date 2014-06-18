module ResourceMap
  class ImportWizard
    def initialize(collection)
      @collection = collection
      @errors = {}
    end

    attr_reader :collection

    def api
      collection.api
    end

    def url
      api.url "en/collections/#{collection.id}/import_wizard"
    end

    def upload(file)
      api.post "en/collections/#{collection.id}/import_wizard/upload_csv", file: file
    end

    def guess_columns_spec
      api.json "en/collections/#{collection.id}/import_wizard/guess_columns_spec"
    end

    def validate_sites_with_columns(columns_spec)
      api.json_post "en/collections/#{collection.id}/import_wizard/validate_sites_with_columns", columns: columns_spec.to_json
    end

    def sites_count(columns_spec)
      validate_sites_with_columns(columns_spec)['sites_count']
    end

    def is_column_spec_valid?(columns_spec)
      if @errors.empty?
        validation = validate_sites_with_columns(columns_spec)
        @errors = validation['errors']
      end
      @errors.values.all? { |v| v.nil? || v.empty? }
    end

    def column_spec_errors(columns_spec)
      errors = @errors.empty? ? validate_sites_with_columns(columns_spec)['errors'] : @errors
      # Under data errors are the repetitions which cause the column to be wrong for identifier. Clarification is in the view
      errors = errors.select {|k,v| !v.nil? && !v.empty? && (k =~ /data_errors/).nil? }
      errors
    end

    def status
      api.json("en/collections/#{collection.id}/import_wizard/job_status")['status'] rescue nil
    end

    def execute(columns_spec)
      h = Hash.new
      columns_spec.each_with_index do |c, i|
        h[i.to_s] = c
      end
      api.post "en/collections/#{collection.id}/import_wizard/execute", columns: h
    end
  end
end
