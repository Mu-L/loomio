<script lang="js">
import AppConfig          from '@/shared/services/app_config';
import Records            from '@/shared/services/records';
import Session            from '@/shared/services/session';
import EventBus           from '@/shared/services/event_bus';
import AbilityService     from '@/shared/services/ability_service';
import RecordLoader       from '@/shared/services/record_loader';
import ThreadService       from '@/shared/services/thread_service';
import WatchRecords from '@/mixins/watch_records';
import FormatDate from '@/mixins/format_date';

export default
{
  mixins: [WatchRecords, FormatDate],
  data() {
    return {
      dashboardLoaded: Records.discussions.collection.data.length > 0,
      filter: this.$route.params.filter || 'hide_muted',
      discussions: [],
      loader: null
    };
  },

  created() {
    this.init();
    EventBus.$on('signedIn', this.init);
  },

  beforeDestroy() {
    EventBus.$off('signedIn', this.init);
  },

  mounted() {
    EventBus.$emit('content-title-visible', false);
    EventBus.$emit('currentComponent', {
      titleKey: 'dashboard_page.aria_label',
      page: 'dashboardPage',
      group: null,
    }
    );
  },

  methods: {
    init() {
      this.loader = new RecordLoader({
        collection: 'discussions',
        path: 'dashboard',
        params: {
          exclude_types: 'poll',
          filter: this.filter,
          per: 60
        }
      });

      this.watchRecords({
        key: 'dashboard',
        collections: ['discussions', 'memberships'],
        query: this.query
      });

      this.refresh();
    },

    refresh() {
      if (!Session.isSignedIn()) { return; }
      this.fetch();
      this.query();
    },

    fetch() {
      if (!this.loader) { return; }
      this.loader.fetchRecords().then(() => { return this.dashboardLoaded = true; });
    },

    query() {
      this.discussions = ThreadService.dashboardQuery();
    }
  },

  computed: {
    noGroups() { return Session.user().groups().length === 0; },
    promptStart() { return this.noGroups && AbilityService.canStartGroups(); },
    userHasMuted() { return Session.user().hasExperienced("mutingThread"); },
    showLargeImage() { return true; }
  }
};

</script>

<template lang="pug">
v-main
  v-container.dashboard-page.max-width-1024.px-0.px-sm-3
    h1.text-h4.my-4(tabindex="-1" v-intersect="{handler: titleVisible}" v-t="'dashboard_page.aria_label'")

    dashboard-polls-panel

    v-card.mb-3(v-if='!dashboardLoaded')
      v-list(lines="two")
        v-list-subheader(v-t="'dashboard_page.recent_threads'")
        loading-content(
          :lineCount='2'
          v-for='(item, index) in [1,2,3]'
          :key='index' )

    div(v-if="dashboardLoaded")
      section.dashboard-page__loaded
        .dashboard-page__empty(v-if='discussions.length == 0')
          p(v-html="$t('dashboard_page.no_groups.show_all')" v-if='noGroups')
          .dashboard-page__no-threads(v-if='!noGroups')
            span(v-show="filter == 'show_all'" v-t="'dashboard_page.no_threads.show_all'")
            //- p(v-t="'dashboard_page.no_threads.show_all'")
            span(v-show="filter == 'show_muted' && userHasMuted", v-t="'dashboard_page.no_threads.show_muted'")
            router-link(to='/dashboard', v-show="filter != 'show_all' && userHasMuted")
              span(v-t="'dashboard_page.view_recent'")
        .dashboard-page__collections(v-if='discussions.length')
          v-card.mb-3.thread-preview-collection__container.thread-previews-container
            v-list.thread-previews(lines="two")
              v-list-subheader(v-t="'dashboard_page.recent_threads'")
              thread-preview(
                v-for="thread in discussions"
                :key="thread.id"
                :thread="thread")
          .dashboard-page__footer(v-if='!loader.exhausted')  
          loading(v-show='loader.loading')
</template>
