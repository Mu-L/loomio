<script lang="js">
import Flash from '@/shared/services/flash';
import EventBus from '@/shared/services/event_bus';

export default
{
  props: {
    membership: Object
  },
  data() {
    return {isDisabled: false};
  },
  methods: {
    submit() {
      this.membership.save().then(() => {
        Flash.success("membership_form.updated");
        EventBus.$emit('closeModal');
      });
    }
  }
}

</script>
<template lang="pug">
v-card.membership-modal(:title="$t('membership_form.modal_title.group')")
  template(v-slot:append)
    dismiss-modal-button
  v-card-text.membership-form
    p.text-medium-emphasis.membership-form__helptext(v-t="{ path: 'membership_form.title_helptext.group', args: { name: membership.user().name } }")
    label(for='membership-title', v-t="'membership_form.title_label'")
    v-text-field#membership-title.membership-form__title-input(autofocus v-on:keyup.enter="submit" :placeholder="$t('membership_form.title_placeholder')" v-model='membership.title', maxlength='255')
    validation-errors(:subject='membership', field='title')
  v-card-actions.membership-form-actions
    v-spacer
    v-btn.membership-form__submit(color="primary" @click='submit()' v-t="'common.action.save'")
</template>
