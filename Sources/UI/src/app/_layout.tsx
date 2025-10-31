import "@/global.css";
import {
	DarkTheme,
	DefaultTheme,
	ThemeProvider,
} from "@react-navigation/native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import "react-native-reanimated";

import { AppConfigProvider } from "@/config/appConfig";
import { useColorScheme } from "@/hooks/useColorScheme";
import { store } from "@/redux/store";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { Provider } from "react-redux";

export default function RootLayout() {
	const colorScheme = useColorScheme();

	return (
		<SafeAreaProvider>
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
		</SafeAreaProvider>
	);
}
