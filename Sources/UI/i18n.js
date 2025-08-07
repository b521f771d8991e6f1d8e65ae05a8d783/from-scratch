import { getLocales } from "expo-localization";
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import translationDE from "./locales/de/translation.json";

const resources = {
	de: { translation: translationDE },
};

const initI18n = async () => {
	let savedLanguage = getLocales()[0].languageCode;
	console.log("Determined language:", savedLanguage);

	i18n.use(initReactI18next).init({
		compatibilityJSON: "v3",
		resources,
		lng: savedLanguage,
		fallbackLng: "de",
		interpolation: {
			escapeValue: false,
		},
	});
};

initI18n();

export default i18n;
