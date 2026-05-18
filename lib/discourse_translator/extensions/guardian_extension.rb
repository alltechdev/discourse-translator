# frozen_string_literal: true
module DiscourseTranslator
  module Extensions
    module GuardianExtension
      POST_DETECTION_BUFFER = 10.seconds

      def user_group_allow_translate?
        return false if !current_user
        current_user.in_any_groups?(SiteSetting.restrict_translation_by_group_map)
      end

      def poster_group_allow_translate?(post)
        return false if !current_user
        return true if SiteSetting.restrict_translation_by_poster_group_map.empty?
        return false if post.user.nil?
        post.user.in_any_groups?(SiteSetting.restrict_translation_by_poster_group_map)
      end

      def can_detect_language?(post)
        (
          SiteSetting.restrict_translation_by_poster_group_map.empty? ||
            post&.user&.in_any_groups?(SiteSetting.restrict_translation_by_poster_group_map)
        ) && post.raw.present? && post.post_type != Post.types[:small_action]
      end

      def can_translate?(post)
        return false if post.user&.bot?
        return false if !user_group_allow_translate?

        # If we haven't detected the post's language yet, hide the globe.
        # This prevents the 🌐 from appearing on the ~48k English posts that
        # predate the plugin install and never had detection run. For brand new
        # posts the globe simply appears ~5s after creation when the detect job
        # finishes — same end UX as the previous buffer-based logic, just without
        # the false positive on permanently-undetected posts.
        return false if post.detected_locale.blank?

        locale = I18n.locale
        return false if post.locale_matches?(locale)
        poster_group_allow_translate?(post)
      end
    end
  end
end
