import { nextTick } from 'vue';
import { createI18n } from 'vue-i18n';
import enData from '@/../../config/locales/client.en.yml';

const clientLocales = import.meta.glob('/../config/locales/client.*.yml')
const dateLocales = import.meta.glob('/node_modules/date-fns/locale/*/index.js')

const en = enData.en
const loadedLocales = ['en'];

const fixCase = function(locale) {
  const splits = locale.replace('-', '_').split('_');
  return compact([splits[0].toLowerCase(), splits[1] && splits[1].toUpperCase()]).join('_');
};

const loomioLocale = locale => locale.replace('-', '_');

const dateFnsLocale = function(locale) {
  if (locale.startsWith('nl')) { return 'nl'; }
  return locale.replace('_','-');
};

export function setupI18n(options = {
  legacy: false,
  locale: 'en',
  fallbackLocale: 'en',
  messages: {en},
  silentTranslationWarn: true
}){
  const i18n = createI18n(options)
  setI18nLanguage(i18n, options.locale)
  return i18n
}

export const I18n = setupI18n();

export async function loadLocaleMessages(i18n, locale) {
  console.log('loadLocaleMessages', locale);
  if (i18n.global.locale.value == locale) {
    return nextTick();
  }

  if (locale != 'en') {
    const dateLocaleKey = `/node_modules/date-fns/locale/${dateFnsLocale(locale)}/index.js`
    const clientLocaleKey = `../config/locales/client.${loomioLocale(locale)}.yml`

    if (!dateLocales[dateLocaleKey]){
      Sentry.captureMessage(`missing dateLocale: ${dateLocaleKey}`)
      return false
    }

    if (!clientLocales[clientLocaleKey]){
      Sentry.captureMessage(`missing clientLocale: ${clientLocaleKey}`)
      return false
    }

    // const dateMessages = await dateLocales[dateLocaleKey]()
    const appMessages = await clientLocales[clientLocaleKey]()
    console.log('appMessages', appMessages);
    i18n.global.setLocaleMessage(locale, appMessages.default[locale])
  }

  // I18n.dateLocale = dateLocale.default

  setI18nLanguage(i18n, locale);

  return nextTick()
}

export function setI18nLanguage(i18n, locale) {
  console.log("i18n.mode", i18n.mode)
  if (i18n.mode === 'legacy') {
    i18n.global.locale = locale
  } else {
    i18n.global.locale.value = locale
  }
  document.querySelector('html').setAttribute('lang', locale)
}
