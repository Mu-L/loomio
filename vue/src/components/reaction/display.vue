<script lang="js">
import Records from '@/shared/services/records';
import Session from '@/shared/services/session';
import ReactionService from '@/shared/services/reaction_service';
import { merge, capitalize, difference, keys, startsWith, each, compact } from 'lodash-es';
import { colonToUnicode, stripColons, srcForEmoji, emojiSupported } from '@/shared/helpers/emojis';
import WatchRecords from '@/mixins/watch_records';

export default {
  mixins: [WatchRecords],

  props: {
    model: Object,
    canEdit: Boolean,
    size: {
      type: String,
      default: 'default'
    }
  },

  data() {
    return {
      diameter: (this.size == 'x-small' && 20) || 24,
      maxNamesCount: 10,
      reactionHash: {all: []},
      emojiSupported
    };
  },

  created() {
    ReactionService.enqueueFetch(this.model);
  },

  mounted() {
    this.watchRecords({
      collections: ['reactions'],
      query: store => {
        this.reactionHash = {all: []};
        each(Records.reactions.find(this.reactionParams), reaction => {
          let user;
          if (this.reactionHash[reaction.reaction] == null) {
            this.reactionHash[reaction.reaction] = [];
          }
          if (user = Records.users.find(reaction.userId)) {
            this.reactionHash[reaction.reaction].push(user);
            this.reactionHash['all'].push(user);
          }
          return true;
        });
      }
    });
  },

    // Records.reactions.enqueueFetch(@reactionParams)

  computed: {
    reactionParams() {
      return {
        reactableType: capitalize(this.model.constructor.singular),
        reactableId: this.model.id
      };
    },

    reactionTypes() {
      return compact(difference(keys(this.reactionHash), ['all']));
    },

    myReaction() {
      if (!Session.isSignedIn()) { return; }
      return Records.reactions.find(merge({}, this.reactionParams, {userId: Session.userId}))[0];
    },

    otherReaction() {
      return Records.reactions.find(merge({}, this.reactionParams, {userId: {'$ne': Session.userId}}))[0];
    },

    reactionTypes() {
      return difference(keys(this.reactionHash), ['all']);
    }
  },

  methods: {
    srcForEmoji,
    stripColons,
    colonToUnicode,
    removeMine(reaction, canEdit) {
      if (!canEdit) { return; }
      const mine = Records.reactions.find(merge({}, this.reactionParams, {
        userId:   Session.user().id,
        reaction
      }
      ))[0];
      if (mine) { mine.destroy(); }
    },

    translate(shortname) {
      const title = emojiTitle(shortname);
      if (startsWith(title, "reactions.")) { return shortname; } else { return title; }
    },

    countFor(reaction) {
      if (this.reactionHash[reaction] != null) {
        return this.reactionHash[reaction].length - this.maxNamesCount;
      } else {
        return 0;
      }
    }
  }
};

</script>
<template lang="pug">
.reactions-display.mr-2(v-if="reactionTypes.length")
  .reactions-display__emojis
    .reaction.lmo-pointer(@click="removeMine(reaction, canEdit)" v-for="reaction in reactionTypes" :key="reaction")
      v-tooltip(bottom)
        template(v-slot:activator="{ attrs }")
          .reactions-display__group(v-bind="attrs")
            span(:class="(size == 'x-small' && 'small') || undefined" v-if="emojiSupported") {{colonToUnicode(reaction)}}
            img.emoji(v-else :src="srcForEmoji(colonToUnicode(reaction))")
            user-avatar.reactions-display__author(no-link v-for="user in reactionHash[reaction]" :key="user.id" :user="user" :size="diameter")
        .reactions-display__name(v-for="user in reactionHash[reaction]" :key="user.id")
          span {{ user.name }}
</template>

<style lang="sass">
.reactions-display__group
  opacity: 0.8
  display: flex
  align-items: center
  margin-right: 2px
  span
    font-size: 22px
    line-height: 20px
  span.small
    font-size: 20px
    line-height: 18px

  .user-avatar
    span
      font-size: 10px
      line-height: 20px
      margin-bottom: -2px
.reactions-display__emojis
  display: flex
</style>
