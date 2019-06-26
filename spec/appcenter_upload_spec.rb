def stub_check_app(status)
  stub_request(:get, "https://api.appcenter.ms/v0.1/apps/owner/app")
    .to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_create_app(status, app_name = "app", app_display_name = "app", app_os = "Android", app_platform = "Java")
  stub_request(:post, "https://api.appcenter.ms/v0.1/apps")
    .with(
      body: "{\"display_name\":\"#{app_display_name}\",\"name\":\"#{app_name}\",\"os\":\"#{app_os}\",\"platform\":\"#{app_platform}\"}",
    )
    .to_return(
      status: status,
      body: "{\"name\":\"app\"}",
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_create_release_upload(status)
  stub_request(:post, "https://api.appcenter.ms/v0.1/apps/owner/app/release_uploads")
    .with(body: "{}")
    .to_return(
      status: status,
      body: "{\"upload_id\":\"upload_id\",\"upload_url\":\"https://upload.com\"}",
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_create_dsym_upload(status)
  stub_request(:post, "https://api.appcenter.ms/v0.1/apps/owner/app/symbol_uploads")
    .with(body: "{\"symbol_type\":\"Apple\"}")
    .to_return(
      status: status,
      body: "{\"symbol_upload_id\":\"symbol_upload_id\",\"upload_url\":\"https://upload_dsym.com\"}",
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_create_mapping_upload(status, version, build, file_name = "mapping.txt")
  stub_request(:post, "https://api.appcenter.ms/v0.1/apps/owner/app/symbol_uploads")
    .with(body: "{\"symbol_type\":\"AndroidProguard\",\"file_name\":\"#{file_name}\",\"build\":\"3\",\"version\":\"1.0.0\"}",)
    .to_return(
      status: status,
      body: "",
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_upload_build(status)
  stub_request(:post, "https://upload.com/")
    .to_return(status: status, body: "", headers: {})
end

def stub_upload_dsym(status)
  stub_request(:put, "https://upload_dsym.com/")
    .to_return(status: status, body: "", headers: {})
end

def stub_upload_mapping(status)
  stub_request(:put, "https://upload_dsym.com/")
    .to_return(status: status, body: "", headers: {})
end

def stub_update_release_upload(status, release_status)
  stub_request(:patch, "https://api.appcenter.ms/v0.1/apps/owner/app/release_uploads/upload_id")
    .with(
      body: "{\"status\":\"#{release_status}\"}"
    )
    .to_return(status: status, body: "{\"release_id\":\"1\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_update_dsym_upload(status, release_status)
  stub_request(:patch, "https://api.appcenter.ms/v0.1/apps/owner/app/symbol_uploads/symbol_upload_id")
    .with(
      body: "{\"status\":\"#{release_status}\"}"
    )
    .to_return(status: status, body: "{\"release_id\":\"1\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_update_mapping_upload(status, release_status)
  stub_request(:patch, "https://api.appcenter.ms/v0.1/apps/owner/app/symbol_uploads/symbol_upload_id")
    .with(
      body: "{\"status\":\"#{release_status}\"}"
    )
    .to_return(status: status, body: "{\"release_id\":\"1\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_get_destination(status, destination_type = "group", destination_name = "Testers")
  stub_request(:get, "https://api.appcenter.ms/v0.1/apps/owner/app/distribution_#{destination_type}s/#{destination_name}")
    .to_return(status: status, body: "{\"id\":\"1\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_update_release(status, release_notes = 'autogenerated changelog')
  stub_request(:put, "https://api.appcenter.ms/v0.1/apps/owner/app/releases/1")
    .with(
      body: "{\"release_notes\":\"#{release_notes}\"}"
    )
    .to_return(status: status, body: "{\"short_version\":\"1.0\",\"download_link\":\"https://download.link\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_get_release(status)
  stub_request(:get, "https://api.appcenter.ms/v0.1/apps/owner/app/releases/1")
    .to_return(status: status, body: "{\"short_version\":\"1.0\",\"download_link\":\"https://download.link\"}", headers: { 'Content-Type' => 'application/json' })
end

def stub_add_to_destination(status, destination_type = "group", mandatory_update = false, notify_testers = false)
  if destination_type == "group"
    body = "{\"id\":\"1\",\"mandatory_update\":#{mandatory_update},\"notify_testers\":#{notify_testers}}"
  else
    body = "{\"id\":\"1\"}"
  end

  stub_request(:post, "https://api.appcenter.ms/v0.1/apps/owner/app/releases/1/#{destination_type}s")
    .with(
      body: body
    )
    .to_return(status: status, body: "{\"short_version\":\"1.0\",\"download_link\":\"https://download.link\"}", headers: { 'Content-Type' => 'application/json' })
end

describe Fastlane::Actions::AppcenterUploadAction do
  describe '#run' do
    before :each do
      allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
    end

    it "raises an error if no api token was given" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("No API token for App Center given, pass using `api_token: 'token'`")
    end

    it "raises an error if no owner name was given" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("No Owner name for App Center given, pass using `owner_name: 'name'`")
    end

    it "raises an error if no app name was given" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            destinations: 'Testers',
            destination_type: 'group',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("No App name given, pass using `app_name: 'app name'`")
    end

    it "raises an error if no build file was given" do
      expect do
        stub_check_app(200)
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Couldn't find build file at path ''")
    end

    it "raises an error if given apk was not found" do
      expect do
        stub_check_app(200)
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            apk: './nothing.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("Couldn't find build file at path './nothing.apk'")
    end

    it "raises an error if given ipa was not found" do
      expect do
        stub_check_app(200)
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            ipa: './nothing.ipa'
          })
        end").runner.execute(:test)
      end.to raise_error("Couldn't find build file at path './nothing.ipa'")
    end

    it "raises an error if given file has invalid extension for apk" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            apk: './spec/fixtures/appfiles/Appfile_empty'
          })
        end").runner.execute(:test)
      end.to raise_error("Only \".apk\" formats are allowed, you provided \"\"")
    end

    it "raises an error if given file has invalid extension for ipa" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            ipa: './spec/fixtures/appfiles/Appfile_empty'
          })
        end").runner.execute(:test)
      end.to raise_error("Only \".ipa\" formats are allowed, you provided \"\"")
    end

    it "raises an error if both ipa and apk provided" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'group',
            ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("You can't use 'ipa' and 'apk' options in one run")
    end

    it "raises an error if destination type is not group or store" do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            destinations: 'Testers',
            destination_type: 'random',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk'
          })
        end").runner.execute(:test)
      end.to raise_error("No or incorrect destination type given. Use 'group' or 'store'")
    end

    it "raises an error on update release upload error" do
      expect do

        stub_check_app(200)
        stub_create_release_upload(200)
        stub_upload_build(200)
        stub_update_release_upload(500, 'committed')

        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Internal Service Error, please try again later")
    end

    it "handles external service response and fails" do
      expect do
        stub_check_app(200)
        stub_create_release_upload(500)
        
        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Internal Service Error, please try again later")
    end

    it "raises an error on upload build failure" do
      expect do
        stub_check_app(200)
        stub_create_release_upload(200)
        stub_upload_build(400)
        stub_update_release_upload(200, 'aborted')

        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Failed to upload release")
    end

    it "raises an error on release upload creation auth failure" do
      expect do
        stub_check_app(200)
        stub_create_release_upload(401)

        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Auth Error, provided invalid token")
    end

    it "handles not found owner or app error" do
      stub_check_app(200)
      stub_create_release_upload(404)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "handles not found distribution group" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200, 'No changelog given')
      stub_get_destination(404)
      stub_get_release(200)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "handles not found release" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200, 'No changelog given')
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(404)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "can use a generated changelog as release notes" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200, 'autogenerated changelog')
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      values = Fastlane::FastFile.new.parse("lane :test do
        Actions.lane_context[SharedValues::FL_CHANGELOG] = 'autogenerated changelog'

        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)

      expect(values[:release_notes]).to eq('autogenerated changelog')
    end

    it "clips changelog if its length is more then 5000" do
      release_notes = '_' * 6000
      read_more = '...'
      release_notes_clipped = release_notes[0, 5000 - read_more.length] + read_more

      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200, release_notes_clipped)
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      values = Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group',
          release_notes: '#{release_notes}'
        })
      end").runner.execute(:test)

      expect(values[:release_notes]).to eq(release_notes_clipped)
    end

    it "clips changelog and adds link in the end if its length is more then 5000" do
      release_notes = '_' * 6000
      release_notes_link = 'https://text.com'
      read_more = "...\n\n[read more](#{release_notes_link})"
      release_notes_clipped = release_notes[0, 5000 - read_more.length] + read_more

      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200, "______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________...\\n\\n[read more](https://text.com)")
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      values = Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group',
          release_notes: '#{release_notes}',
          release_notes_link: '#{release_notes_link}'
        })
      end").runner.execute(:test)

      expect(values[:release_notes]).to eq(release_notes_clipped)
    end

    it "works with valid parameters for android" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "uses GRADLE_APK_OUTPUT_PATH as default for apk" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      values = Fastlane::FastFile.new.parse("lane :test do
        Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] = './spec/fixtures/appfiles/apk_file_empty.apk'

        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)

      expect(values[:apk]).to eq('./spec/fixtures/appfiles/apk_file_empty.apk')
    end

    it "uses IPA_OUTPUT_PATH as default for ipa" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      values = Fastlane::FastFile.new.parse("lane :test do
        Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] = './spec/fixtures/appfiles/ipa_file_empty.ipa'

        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)

      expect(values[:ipa]).to eq('./spec/fixtures/appfiles/ipa_file_empty.ipa')
    end

    it "works with valid parameters for ios" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "uses proper api for mandatory release" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200, 'group', true, false)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers',
          destination_type: 'group',
          mandatory_update: true
        })
      end").runner.execute(:test)
    end

    it "uses proper api for release with email notification parameter" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200, 'group', false, true)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers',
          destination_type: 'group',
          notify_testers: true
        })
      end").runner.execute(:test)
    end

    it "uses proper api for mandatory release with email notification parameter" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200, 'group', true, true)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers',
          destination_type: 'group',
          mandatory_update: true,
          notify_testers: true
        })
      end").runner.execute(:test)
    end

    it "adds to all provided groups" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200, 'group', 'Testers1')
      stub_get_destination(200, 'group', 'Testers2')
      stub_get_destination(200, 'group', 'Testers3')
      stub_add_to_destination(200)
      stub_add_to_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers1,Testers2,Testers3',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "encodes group names" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200, 'group', 'Testers%201')
      stub_get_destination(200, 'group', 'Testers%202')
      stub_get_destination(200, 'group', 'Testers%203')
      stub_add_to_destination(200)
      stub_add_to_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers 1,Testers 2,Testers 3',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "can release to store" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200, 'store')
      stub_add_to_destination(200, 'store')
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip',
          destinations: 'Testers',
          destination_type: 'store'
        })
      end").runner.execute(:test)
    end

    it "creates app if it was not found" do
      stub_check_app(404)
      stub_create_app(200, "app", "app", "Android", "Java")
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "creates app if it was not found with specified os, platform and display_name" do
      stub_check_app(404)
      stub_create_app(200, "app", "App Name", "Android", "Java")
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          app_display_name: 'App Name',
          app_os: 'Android',
          app_platform: 'Java',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "handles app creation error" do
      stub_check_app(404)
      stub_create_app(500)

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "allows to send android mappings" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_mapping_upload(200, "1.0.0", "3")
      stub_upload_mapping(200)
      stub_update_mapping_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          mapping: './spec/fixtures/symbols/mapping.txt',
          build_number: '3',
          version: '1.0.0',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "allows to send android mappings with custom name" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_mapping_upload(200, "1.0.0", "3", "renamed-mapping.txt")
      stub_upload_mapping(200)
      stub_update_mapping_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          apk: './spec/fixtures/appfiles/apk_file_empty.apk',
          mapping: './spec/fixtures/symbols/renamed-mapping.txt',
          build_number: '3',
          version: '1.0.0',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)
    end

    it "allows to send only android mappings" do
      stub_check_app(200)
      stub_create_mapping_upload(200, "1.0.0", "3", "renamed-mapping.txt")
      stub_upload_mapping(200)
      stub_update_mapping_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          upload_mapping_only: true,
          mapping: './spec/fixtures/symbols/renamed-mapping.txt',
          build_number: '3',
          version: '1.0.0'
        })
      end").runner.execute(:test)
    end

    it "zips dSYM files if dsym parameter is folder" do
      stub_check_app(200)
      stub_create_release_upload(200)
      stub_upload_build(200)
      stub_update_release_upload(200, 'committed')
      stub_update_release(200)      
      stub_get_destination(200)
      stub_add_to_destination(200)
      stub_get_release(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      values = Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          ipa: './spec/fixtures/appfiles/ipa_file_empty.ipa',
          dsym: './spec/fixtures/symbols/Themoji.dSYM',
          destinations: 'Testers',
          destination_type: 'group'
        })
      end").runner.execute(:test)

      expect(values[:dsym_path].end_with?(".zip")).to eq(true)
    end

    it "allows to send a dsym only" do
      stub_check_app(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          upload_dsym_only: true,
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip'
        })
      end").runner.execute(:test)
    end

    it "uses DSYM_OUTPUT_PATH as default for dsym" do
      stub_check_app(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(200)
      stub_update_dsym_upload(200, "committed")

      values = Fastlane::FastFile.new.parse("lane :test do
        Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH] = './spec/fixtures/symbols/Themoji.dSYM.zip'

        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          upload_dsym_only: true,
        })
      end").runner.execute(:test)

      expect(values[:dsym_path]).to eq('./spec/fixtures/symbols/Themoji.dSYM.zip')
    end

    it "handles invalid token error" do
      expect do
        stub_check_app(200)
        stub_create_release_upload(401)

        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            apk: './spec/fixtures/appfiles/apk_file_empty.apk',
            destinations: 'Testers',
            destination_type: 'group'
          })
        end").runner.execute(:test)
      end.to raise_error("Auth Error, provided invalid token")
    end

    it "handles invalid token error in dSYM upload" do
      expect do
        stub_check_app(200)
        stub_create_dsym_upload(401)

        Fastlane::FastFile.new.parse("lane :test do
          appcenter_upload({
            api_token: 'xxx',
            owner_name: 'owner',
            app_name: 'app',
            upload_dsym_only: true,
            dsym: './spec/fixtures/symbols/Themoji.dSYM.zip'
          })
        end").runner.execute(:test)
      end.to raise_error("Auth Error, provided invalid token")
    end

    it "handles upload dSYM error" do
      stub_check_app(200)
      stub_create_dsym_upload(200)
      stub_upload_dsym(400)
      stub_update_dsym_upload(200, 'aborted')

      Fastlane::FastFile.new.parse("lane :test do
        appcenter_upload({
          api_token: 'xxx',
          owner_name: 'owner',
          app_name: 'app',
          upload_dsym_only: true,
          dsym: './spec/fixtures/symbols/Themoji.dSYM.zip'
        })
      end").runner.execute(:test)
    end
  end
end
