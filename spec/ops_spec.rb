require 'spec_helper'

describe 'Test basic functions' do
  describe 'Correct' do
    describe 'Signature' do
      before do
        add_config(false, false)
        @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

        add_config(true, false)
        @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      end

      it 'Must generate signature' do
        @mail.body.to_s.should_not eql @raw_mail.body.to_s
      end

      it 'Verification check' do
        verified = @mail.proceed(Notifier.x509_configuration)
        verified.should eql @raw_mail.body.to_s
      end
    end

    describe 'Crypting' do
      before do
        add_config(false, false)
        @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

        add_config(false, true)
        @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      end

      it 'Must generate crypted text' do
        @mail.body.decoded.should_not eql @raw_mail.body.decoded
      end

      it 'Must generate crypted text' do
        decrypted = @mail.proceed(Notifier.x509_configuration)
        decrypted.to_s.should eql @raw_mail.body.decoded
      end
    end

    it 'Crypting and Signature' do
      add_config(false, false)
      raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      decrypted = mail.proceed(Notifier.x509_configuration)
      decrypted.to_s.should eql raw_mail.body.decoded
    end
  end

  describe 'Incorrect' do
    it 'sign incorrect key' do
      add_config(true, false)

      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      mail.body.to_s.should_not be_empty

      set_config_param(sign_passphrase: 'wrong')
      -> { mail.proceed(Notifier.x509_configuration) }.should raise_error OpenSSL::PKey::RSAError
    end

    describe 'incorrect text' do
      it 'sign' do
        add_config(true, false)
        mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
        mail.body = mail.body.to_s.gsub(/[0-9]/, 'g')
        -> { mail.proceed(Notifier.x509_configuration) }.should raise_error VerificationError
      end

      it 'crypt' do
        add_config(false, true)
        mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
        mail.body = mail.body.to_s.gsub(/[0-9]/, 'g')
        -> { mail.proceed(Notifier.x509_configuration) }.should raise_error DecodeError
      end
    end

    describe 'incorrect certs' do
      it 'sign' do
        add_config(true, false)
        set_config_param(crypt_cert: 'cert.crt',
                         crypt_key: 'cert.key')
        mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
        mail.body = mail.body.to_s.gsub(/[0-9]/, 'g')
        -> { mail.proceed(Notifier.x509_configuration) }.should raise_error VerificationError
      end

      it 'crypt' do
        add_config(false, true)
        set_config_param(crypt_cert: 'cert.crt',
                         crypt_key: 'cert.key')
        -> { Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>') }.should raise_error OpenSSL::PKey::RSAError
      end
    end
  end
end