<script lang="js">
import Records     from '@/shared/services/records';
import FlashService   from '@/shared/services/flash';
import { hoursOfDay, timeFormat } from '@/shared/helpers/format_time';
import { format, parse, isValid } from 'date-fns';
import { mdiCalendar, mdiClockOutline } from '@mdi/js';
import { I18n } from '@/i18n';

export default {
  props: {
    modelValue: Date,
    min: Date,
  },

  created() {
    return this.newValue = this.value;
  },

  data() {
    return {
      mdiCalendar,
      mdiClockOutline,
      dateVal: new Date(),
      timeStr: (this.modelValue && format(this.modelValue, 'HH:mm')) || '12:00',
      times: hoursOfDay(),
      dateToday: new Date(),
      validDate: val => {
        return isValid(parse(val, "yyyy-MM-dd", new Date()));
      }
    };
  },

  methods: {
    updateNewValue() {
      const val = parse(`${format(this.dateVal, "yyyy-MM-dd")} ${this.timeStr}`, "yyyy-MM-dd HH:mm", new Date);
      if (!isValid(val)) { return; }
      this.newValue = val;
      this.$emit('update:modelValue', this.newValue);
    }
  },

  watch: {
    dateVal() { this.updateNewValue(); },
    timeStr() { this.updateNewValue(); }
  },

  computed: {
    twelvehour() { return timeFormat() !== 'HH:mm'; },
    timeHint() {
      try {
        const d = parse(this.timeStr, 'HH:mm', new Date);
        return format(d, timeFormat());
      } catch (error) {
        FlashService.error("poll_meeting_form.use_24_hour_format", {time: format(new Date, 'HH:mm')});
        return I18n.global.t("poll_meeting_form.use_24_hour_format", {time: format(new Date, 'HH:mm')});
      }
    }
  }
};
</script>
<template lang="pug">
.d-flex.date-time-picker.flex-grow-1
  lmo-date-input.mr-2(
    v-model='dateVal'
    :prepend-inner-icon="mdiCalendar"
    :min="dateToday"
    persistent-hint
  )
  v-combobox.date-time-picker__time-field(
    :hint="twelvehour ? timeHint : null"
    :persistent-hint="twelvehour"
    v-model="timeStr"
    :items="times"
    :prepend-inner-icon="mdiClockOutline")
</template>
