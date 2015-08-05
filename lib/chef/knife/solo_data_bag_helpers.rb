require 'chef/knife'
require 'aws-sdk'

class Chef
  class Knife

    module SoloDataBagHelpers

      def bag_item_path
        File.expand_path File.join(bag_path, "#{item_name}.json")
      end

      def bag_path
        File.expand_path File.join(bags_path, bag_name)
      end

      def bags_path
        if config[:data_bag_path]
          Chef::Config[:data_bag_path] = config[:data_bag_path]
        end

        Chef::Config[:data_bag_path]
      end

      def persist_bag_item(item)
        File.open bag_item_path, 'w' do |f|
          f.write JSON.pretty_generate(item.raw_data)
        end
      end

      def secret_path
        Chef::Config[:encrypted_data_bag_secret]
      end

      def secret_key
        return config[:secret] if config[:secret]
        Chef::EncryptedDataBagItem.load_secret(config[:secret_file] || secret_path)
      end

      def should_be_encrypted?
        config[:secret] || config[:secret_file] || secret_path
      end

      def convert_json_string
        JSON.parse config[:json_string]
      end

      def validate_bag_name_provided
        unless bag_name
          show_usage
          ui.fatal 'You must supply a name for the data bag'
          exit 1
        end
      end

      def validate_bags_path_exists
        unless File.directory? bags_path
          raise Chef::Exceptions::InvalidDataBagPath,
            "Configured data bag path '#{bags_path}' is invalid"
        end
      end

      def validate_json_string
        begin
          JSON.parse config[:json_string], :create_additions => false
        rescue => error
          raise "Syntax error in #{config[:json_string]}: #{error.message}"
        end
      end

      def validate_multiple_secrets_were_not_provided
        if config[:secret] && config[:secret_file_path]
          show_usage
          ui.fatal 'Please specify either --secret or --secret-file only'
          exit 1
        elsif (config[:secret] && secret_path) || (config[:secret_file_path] && secret_path)
          ui.warn 'The encrypted_data_bag_secret option defined in knife.rb was overriden by the command line.'
        end
      end

      def validate_environment_if_secret_file_path_is_provided
        if config[:secret_file_path] && config[:environment].nil?
          show_usage
          ui.fatal 'Please specify chef environment using -E or --environment as you supplied secret file path'
          exit 1
        end
      end

      def validate_aws_regions
        aws_regions = %w(
        us-east-1 us-west-2 eu-west-1 eu-central-1 ap-southeast-1 ap-northeast-1 ap-southeast-2 sa-east-1 us-west-1)
        if config[:region] && !aws_regions.include?(config[:region])
          ui.fatal "Given aws region is invalid . The following are the supported regions #{aws_regions.join(',')}"
          exit 1
        end
      end

      def resolve_secret_file
        if config[:secret_file_path]
          secret_file = File.join(config[:secret_file_path], "encrypted_data_bag_secret-#{config[:environment]}")
          if config[:enable_aws_kms]
            encrypted_content = File.new(secret_file).read
            client = Aws::KMS::Client.new(region: config[:region])
            resp = client.decrypt({ ciphertext_blob: encrypted_content })
            config[:secret] = resp.plaintext
          else
            config[:secret_file] = secret_file
          end
        end
      end

    end

  end
end
