<script lang="js">
export default {
  props: {
    stance: Object
  }
};
</script>

<template lang="pug">
.poll-common-change-your-vote
  v-list-subheader(v-t="'poll_common.your_response'")
  poll-common-stance(:stance="stance")
</template>
