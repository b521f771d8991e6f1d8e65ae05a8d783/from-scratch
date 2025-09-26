import {
	DarkTheme,
	DefaultTheme,
	ThemeProvider,
} from "@react-navigation/native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import "react-native-reanimated";
import "@/global.css";

import { AppConfigProvider } from "@/config/appConfig";
import { useColorScheme } from "@/hooks/useColorScheme";
import { store } from "@/redux/store";
import { Provider } from "react-redux";

export default function RootLayout() {
	const colorScheme = useColorScheme();

	return (
		<AppConfigProvider>
			<Provider store={store}>
				<ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
					<Stack>
						<Stack.Screen name="(tabs)" options={{ headerShown: false }} />
						<Stack.Screen name="+not-found" />
					</Stack>
					<StatusBar style="auto" />
				</ThemeProvider>
			</Provider>
		</AppConfigProvider>
	);
}
