<script lang="js">
import AppConfig from '@/shared/services/app_config';
import EventBus from '@/shared/services/event_bus';
import Session from '@/shared/services/session';
import Records from '@/shared/services/records';
import md5 from 'md5';
import { I18n } from '@/i18n';

export default {
  data() {
    return {
      notice: false,
      showNotice: false,
      showDismiss: false,
      reload: false
    };
  },

  mounted() {
    setInterval(() => {
      return Records.fetch({
        path: 'boot/version',
        params: {
          version: AppConfig.version,
          release: AppConfig.release,
          now: Date.now()
        }}).then(this.eatData);
    } , 1000 * 60 * 5);
    EventBus.$on('systemNotice', this.eatData);
    EventBus.$on('signedIn', () => { return this.showNotice = false; });
    this.eatData({version: AppConfig.version, notice: AppConfig.systemNotice});
  },

  methods: {
    eatData(data) {
      this.reload = data.reload;
      this.notice = data.notice || (AppConfig.features.app.trials && this.$route.path.startsWith('/d/') && !Session.isSignedIn() && I18n.global.t("powered_by.this_is_loomio_md"));
      this.showNotice = this.reload || (this.notice && !Session.user().hasExperienced(md5(this.notice)));
      this.showDismiss = data.reload || data.notice;
    },

    accept() {
      this.showNotice = false;
      this.notice && Records.users.saveExperience(md5(this.notice));
      if (this.reload) {
        setTimeout(() => location.reload() , 100);
      }
    }
  }
};

</script>

<template lang="pug">
v-system-bar.system-notice(v-if="showNotice" app color="primary" height="40")
  .d-flex.justify-space-between(style="width: 100%")
    .system-notice__message.text-subtitle-1
      span(v-if="notice" v-marked="notice")
      span(v-else="notice" v-t="'global.messages.app_update'")
    v-btn.system-notice__hide(
      v-if="showDismiss"
      size="small"
      variant="tonal"
      @click="accept"
      v-t="(reload && 'global.messages.reload') || 'dashboard_page.dismiss'"
    )
</template>

<style lang="sass">
.system-notice

  p
    color: #fff
    margin-top: 0
    margin-bottom: 0
    a
      color: #fff
      text-decoration: underline
</style>
