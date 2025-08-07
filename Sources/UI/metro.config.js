const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");

const config = getDefaultConfig(__dirname);

config.transformer.minifierConfig = {
	compress: {
		drop_console: true,
	},
};

module.exports = withNativeWind(config, { input: "./global.css" });
