require 'tempfile'
require 'tmpdir'

module GPG
  class Engine
    attr_accessor :runner
    attr_accessor :verbose

    def initialize(runner = nil, verbose = false)
      self.runner = runner || GPG::Runner.new
      self.verbose = verbose
      self.runner.verbose = self.verbose
    end

    def import_key(key_contents)
      log("Import Key")
      validate_gpg_version
      Tempfile.open do |f|
        f.write(key_contents)
        f.rewind

        runner.import_key_from_file(f.path)
      end
    end

    def verify_signature(signature_data)
      log("Verify Signature")

      validate_gpg_version

      data = ''
      result = false

      GPG::TempPathHelper.create do |path1|
        GPG::TempPathHelper.create do |path2|
          File.write(path1, signature_data)
          result = runner.verify_signature_file(path1, path2)

          data = File.read(path2) if result
        end
      end

      [result, data]
    end

    def decrypt(encrypted_data, passphrase=nil)
      log("Decrypt")

      validate_gpg_version

      data = ''
      result = false

      GPG::TempPathHelper.create do |path1|
        GPG::TempPathHelper.create do |path2|
          File.write(path1, encrypted_data)
          result = runner.decrypt_file(path1, path2, passphrase)

          data = File.read(path2) if result
        end
      end

      [result, data]
    end

    def encrypt(plaintext_data, recipients)
      log("Encrypt")

      raise 'Recipients cannot be empty' if recipients.empty?

      data = ''
      result = false

      GPG::TempPathHelper.create do |path1|
        GPG::TempPathHelper.create do |path2|
          File.write(path1, plaintext_data)
          result = runner.encrypt_file(path1, path2, recipients)

          data = File.read(path2) if result
        end
      end

      [result, data]
    end

    def sign(plaintext_data, passphrase=nil)
      log("Sign")

      data = ''
      result = false

      GPG::TempPathHelper.create do |path1|
        GPG::TempPathHelper.create do |path2|
          File.write(path1, plaintext_data)
          result = runner.sign_file(path1, path2, passphrase)

          data = File.read(path2) if result
        end
      end

      [result, data]
    end

    def delete_all_keys
      delete_all_private_keys
      delete_all_public_keys
    end

    def delete_all_private_keys
      log('Delete all private keys')
      validate_gpg_version
      runner.read_private_key_fingerprints.each do |k|
        runner.delete_private_key k
      end
    end

    def delete_all_public_keys
      log('Delete all public keys')
      validate_gpg_version
      runner.read_public_key_fingerprints.each do |k|
        runner.delete_public_key k
      end
    end

    def read_recipients
      public_recipients = runner.read_public_key_recipients
      private_recipients = runner.read_private_key_recipients
      (public_recipients + private_recipients).uniq
    end

    protected

    def log(message)
      if verbose
        PGP::Log.logger.info(message)
      end
    end

    def validate_gpg_version
      raise 'GPG Version is incorrect' unless runner.version_default.start_with?('2.')
    end
  end
end