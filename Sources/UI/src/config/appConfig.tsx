//import { AppConfig } from "../../../generated/npm-pkgs/backend-interfaces/backend_interfaces";

import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { createContext, useContext, useEffect, useState } from "react";
import { Platform, Text } from "react-native";

const CONFIG_STORAGE_KEY = "APP_CONFIG";
const LAST_UPDATED_KEY = "APP_CONFIG_LAST_UPDATED";
const DAYS_THRESHOLD = 7;

export interface AppConfig {}

/**
 * Constructs the backend URL by combining the current window's origin
 * with the API prefix defined in the environment variables.
 *
 * @returns {string} The full backend URL.
 */
export function getBackendURL(url: string | undefined = undefined) {
	const prefix =
		Platform.OS === "web" ? "" : process.env.EXPO_PUBLIC_BACKEND_URL;
	return (
		prefix + "/" + process.env.EXPO_PUBLIC_API_PREFIX + (url ? `/${url}` : "")
	);
}

export async function downloadAppConfig(
	appConfigUrl: string = getBackendURL("app-config.json"),
): Promise<AppConfig | undefined> {
	console.log("Downloading App Config from", appConfigUrl);

	try {
		const result = await fetch(appConfigUrl);

		if (!result.ok) {
			console.error(
				`Failed to fetch AppConfig. HTTP status: ${result.status}, Status text: ${result.statusText}`,
			);
			return await loadAppConfig(); // Attempt to load from Async Storage if fetch fails
		}

		const resultText = await result.text();

		if (!resultText) {
			console.error("AppConfig response is empty or invalid text.");
			return await loadAppConfig(); // Attempt to load from Async Storage if response is invalid
		}

		const appConfig = JSON.parse(resultText) as AppConfig;

		// Save the app config to Async Storage
		await AsyncStorage.setItem(CONFIG_STORAGE_KEY, resultText);
		console.log("App Config saved to Async Storage.");

		// Save the current timestamp to LAST_UPDATED_KEY
		const currentTime = new Date().getTime().toString();
		await AsyncStorage.setItem(LAST_UPDATED_KEY, currentTime);
		console.log("Last updated timestamp saved to Async Storage.");

		return appConfig;
	} catch (error) {
		console.error("An error occurred while downloading AppConfig:", error);
		return await loadAppConfig(); // Attempt to load from Async Storage on error
	}
}

async function loadAppConfig(): Promise<AppConfig | undefined> {
	try {
		const storedConfig = await AsyncStorage.getItem(CONFIG_STORAGE_KEY);
		const lastUpdated = await AsyncStorage.getItem(LAST_UPDATED_KEY);
		const currentTime = new Date().getTime();
		const thresholdTime = DAYS_THRESHOLD * 24 * 60 * 60 * 1000; // Convert days to milliseconds

		if (storedConfig) {
			const config = JSON.parse(storedConfig) as AppConfig;
			const lastUpdatedTime = lastUpdated ? parseInt(lastUpdated, 10) : 0;

			// Check if the config is older than the threshold
			if (currentTime - lastUpdatedTime > thresholdTime) {
				console.log("App Config is outdated. Attempting to reload...");

				// Attempt to reload the config (you can replace this with your actual reload logic)
				const newConfig = await downloadAppConfig(); // Implement this function to fetch new config
				if (newConfig) {
					console.log("Successfully reloaded App Config.");
					await AsyncStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(newConfig));
					await AsyncStorage.setItem(LAST_UPDATED_KEY, currentTime.toString());
					return newConfig;
				} else {
					console.error("Failed to reload App Config. Keeping the current one.");
					return config; // Return the current config if reload fails
				}
			} else {
				console.log("Loaded App Config from Async Storage.");
				return config; // Return the stored config if it's still valid
			}
		} else {
			throw new Error("No App Config found in Async Storage.");
		}
	} catch (error) {
		console.error(error);
		throw new Error(
			"An error occurred while loading AppConfig from Async Storage",
		);
	}
}

async function determineAppConfig(): Promise<AppConfig | undefined> {
	const storedConfig = await loadAppConfig();

	if (storedConfig) {
		return storedConfig;
	} else {
		return await downloadAppConfig();
	}
}

export function AppConfigProvider({ children }: { children: React.ReactNode }) {
	const [config, setConfig] = useState<AppConfig | undefined>(undefined);
	const [error, setError] = useState<string | null>(null); // State to hold error messages

	useEffect(() => {
		async function fetchConfig() {
			try {
				const appConfig = await determineAppConfig();
				setConfig(appConfig);
			} catch (err) {
				setError("Failed to load configuration. Please try again later."); // Set error message
			}
		}

		fetchConfig();
	}, []);

	if (error) {
		return <Text>{error}</Text>; // Display error message
	}

	if (!config) {
		return <Text>Loading...</Text>; // You can replace this with a loading spinner or any other placeholder
	}

	return (
		<AppConfigContext.Provider value={config}>
			{children}
		</AppConfigContext.Provider>
	);
}

const AppConfigContext = createContext<AppConfig | undefined>(undefined);

export function useAppConfig() {
	const context = useContext(AppConfigContext);
	if (context === undefined) {
		throw new Error("useAppConfig must be used within an AppConfigProvider");
	}
	return context;
}
