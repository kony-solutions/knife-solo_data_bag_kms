require 'chef/knife'

class Chef
  class Knife

    class SoloDataBagShow < Knife

      require 'chef/knife/solo_data_bag_helpers'
      include Chef::Knife::SoloDataBagHelpers

      banner 'knife solo data bag show BAG [ITEM] (options)'
      category 'solo data bag'

      attr_reader :bag_name, :item_name

      option :secret,
        :short => '-s SECRET',
        :long  => '--secret SECRET',
        :description => 'The secret key to use to encrypt data bag item values'

      option :secret_file_path,
        :long  => '--secret-file-path SECRET_FILE',
        :description => 'A file containing the secret key to use to encrypt data bag item values'

      option :enable_aws_kms,
        :long => '--enable-aws-kms',
        :description => 'Flag to enable decryption of data bag secret using AWS KMS',
        :boolean => true

      option :region,
         :short => '-r AWS_REGION',
         :long => '--region AWS_REGION',
         :description => 'AWS Region to be used for decryption via AWS KMS',
         :default => 'us-east-1'

      option :data_bag_path,
        :long => '--data-bag-path DATA_BAG_PATH',
        :description => 'The path to data bag'

      def run
        Chef::Config[:solo]   = true
        @bag_name, @item_name = @name_args
        ensure_valid_arguments
        resolve_secret_file
        display_content
      end

      private
      def bag_content
        Chef::DataBag.load bag_name
      end

      def bag_item_content
        if should_be_encrypted?
          raw = Chef::EncryptedDataBagItem.load(bag_name, item_name, secret_key)
          raw.to_hash
        else
          Chef::DataBagItem.load(bag_name, item_name).raw_data
        end
      end

      def display_content
        content = item_name ? bag_item_content : bag_content
        output format_for_display(content)
      end

      def ensure_valid_arguments
        validate_bag_name_provided
        validate_bags_path_exists
        validate_multiple_secrets_were_not_provided
        validate_environment_if_secret_file_path_is_provided
        validate_aws_regions
      end

    end

  end
end
