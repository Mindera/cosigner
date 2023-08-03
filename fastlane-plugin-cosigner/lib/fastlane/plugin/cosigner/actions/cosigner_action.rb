module Fastlane
  module Actions
    class CosignerAction < Action
      def self.run(params)
        require 'xcodeproj'
        require 'colorize'

        project = Xcodeproj::Project.open(params[:xcodeproj_path])

        target = project.targets.select{ |target| target.name == params[:scheme] }.first
        project_attributes = project.root_object.attributes
        build_settings = target.build_configuration_list[params[:build_configuration]].build_settings

        # The new `ProvisioningStyle` setting on Xcode 8 apparently was migrated to the `CODE_SIGN_STYLE` build setting
        # Since we can't know for sure which Xcode version is running, apply both values
        UI.message "Updating Xcode project's `ProvisioningStyle` (Xcode 8) and `CODE_SIGN_STYLE` (Xcode 9+) to \"#{params[:code_sign_style]}\" 🛠".green
        if project_attributes['TargetAttributes'] == nil
          project_attributes['TargetAttributes'] = {}
          project_attributes['TargetAttributes'][target.uuid] = {}
        end
        project_attributes['TargetAttributes'][target.uuid]['ProvisioningStyle'] = params[:code_sign_style]
        build_settings['CODE_SIGN_STYLE'] = params[:code_sign_style]

        UI.message "Updating Xcode project's `CODE_SIGN_IDENTITY` to \"#{params[:code_sign_identity]}\" 🔑".green
        build_settings['CODE_SIGN_IDENTITY'] = params[:code_sign_identity]
        build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = params[:code_sign_identity]

        UI.message "Updating Xcode project's `PROVISIONING_PROFILE_SPECIFIER` to \"#{params[:profile_name]}\" 🔧".green
        build_settings['PROVISIONING_PROFILE_SPECIFIER'] = params[:profile_name]

        # This item is set as optional in the configuration values
        # Since Xcode 8, this is no longer needed, you use PROVISIONING_PROFILE_SPECIFIER
        if params[:profile_uuid]
            UI.message "Updating Xcode project's `PROVISIONING_PROFILE` to \"#{params[:profile_uuid]}\" 🔧".green
            build_settings['PROVISIONING_PROFILE'] = params[:profile_uuid]
        end

        if params[:development_team]
            UI.message "Updating Xcode project's `DEVELOPMENT_TEAM` to \"#{params[:development_team]}\" 👯".green
            build_settings['DEVELOPMENT_TEAM'] = params[:development_team]
        end

        if params[:bundle_identifier]
            UI.message "Updating Xcode project's `PRODUCT_BUNDLE_IDENTIFIER` \"#{params[:bundle_identifier]}\" 🤗".green
            build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = params[:bundle_identifier]
        end

        project.save
      end

      def self.description
        "A fastlane plugin to help you sign your iOS builds"
      end

      def self.authors
        ["mindera.com", "p4checo", "portellaa"]
      end

      def self.details
        "
Fastlane plugin which enables iOS workflows to change the Xcode project's code signing settings before building a target, being a \"cosigner\" 🖋.

This action is especially useful to avoid having to configure the Xcode project with a \"static\" set of code signing configurations for:

 * Code Signing Style (Xcode8+): Manual / Automatic (also called Provisioning Style on Xcode 8)
 * Code Signing Identity: iPhone Development / iPhone Distribution
 * Provisioning Profile UUID (Xcode 7 and earlier)
 * Provisioning Profile Name (Xcode8+)
 * Team ID
 * Application Bundle identifier

By being able to configure this before each build (e.g. `gym` call), it allows having separate sets of code signing configurations on the same project without being \"intrusive\".

Some practical scenarios can be for example:

 * Xcode project in which two different Apple Developer accounts/teams are required (e.g. 1 for Development and 1 for Release)
 * Shared Xcode project where teams have different code signing configurations (e.g. Automatic vs Manual Provisioning Style)
        "
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :xcodeproj_path,
                                         env_name: "PROJECT_PATH",
                                         description: "The Project Path"),
            FastlaneCore::ConfigItem.new(key: :scheme,
                                         env_name: "SCHEME",
                                         description: "Scheme"),
            FastlaneCore::ConfigItem.new(key: :build_configuration,
                                         env_name: "BUILD_CONFIGURATION",
                                         description: "Build configuration (Debug, Release, ...)"),
            FastlaneCore::ConfigItem.new(key: :code_sign_style,
                                         env_name: "CODE_SIGN_STYLE",
                                         description: "Code Sign (Provisioning) style (Automatic, Manual)",
                                         default_value: "Manual"),
            FastlaneCore::ConfigItem.new(key: :code_sign_identity,
                                         env_name: "CODE_SIGN_IDENTITY",
                                         description: "Code signing identity type (iPhone Development, iPhone Distribution)",
                                         default_value: "iPhone Distribution"),
            FastlaneCore::ConfigItem.new(key: :profile_name,
                                         env_name: "PROVISIONING_PROFILE_SPECIFIER",
                                         description: "Provisioning profile name to use for code signing"),
            FastlaneCore::ConfigItem.new(key: :profile_uuid,
                                         env_name: "PROVISIONING_PROFILE",
                                         description: "Provisioning profile UUID to use for code signing",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :development_team,
                                         env_name: "TEAM_ID",
                                         description: "Development team identifier",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :bundle_identifier,
                                         env_name: "APP_IDENTIFIER",
                                         description: "Application Product Bundle Identifier",
                                         optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
