import { Image } from "expo-image";
import { StyleSheet, Text, useColorScheme } from "react-native";

import ParallaxScrollView from "@/components/ParallaxScrollView";
import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { useAppConfig } from "@/config/appConfig";
import {
	useGetBackendStatusQuery,
	useGetBackendVersionQuery,
} from "@/redux/state/apiSlice";
import { useGetPrivateBackendStatusQuery } from "@/redux/state/privateApiSlice";
import { useTranslation } from "react-i18next";

export default function AboutScreen() {
	const appConfig = useAppConfig();
	const colorScheme = useColorScheme();
	const { t } = useTranslation();
	const {
		isLoading: statusIsLoading,
		data: status,
		error: statusError,
		isSuccess: statusLoaded,
	} = useGetBackendStatusQuery();

	const {
		isLoading: versionIsLoading,
		data: version,
		error: versionError,
		isSuccess: versionLoaded,
	} = useGetBackendVersionQuery();

	const {
		isLoading: privateBackendStatusIsLoading,
		data: privateBackendStatus,
		error: privateBackendStatusError,
		isSuccess: privateBackendStatusLoaded,
	} = useGetPrivateBackendStatusQuery();

	if (statusIsLoading || versionIsLoading || privateBackendStatusIsLoading) {
		return <ThemedText>Loading</ThemedText>;
	}

	function DisplayStatus({ data, error, isSuccess }: any) {
		if (error) {
			console.error(error);
		}
		return (
			<Text>
				{isSuccess && data && "👌"} {error && "❌"}
			</Text>
		);
	}

	return (
		<ParallaxScrollView
			headerBackgroundColor={{ light: "#A1CEDC", dark: "#1D3D47" }}
			headerImage={
				<Image
					source={require("@/assets/images/logo.svg")}
					style={styles.reactLogo}
				/>
			}
		>
			<ThemedView style={styles.titleContainer}>
				<Text>
					{t("about.made_by")}: {process.env.EXPO_PUBLIC_APP_VENDOR}
				</Text>
				<Text>
					Backend /api/private Status:{" "}
					<DisplayStatus
						data={privateBackendStatus}
						error={privateBackendStatusError}
						isSuccess={privateBackendStatusLoaded}
					/>
				</Text>
				<Text>
					Backend /api Status:{" "}
					<DisplayStatus
						data={status}
						error={statusError}
						isSuccess={statusLoaded}
					/>
				</Text>
				<Text>Backend version: {versionLoaded && version} </Text>
			</ThemedView>
		</ParallaxScrollView>
	);
}

const styles = StyleSheet.create({
	titleContainer: {
		flexDirection: "row",
		alignItems: "center",
		gap: 8,
	},
	stepContainer: {
		gap: 8,
		marginBottom: 8,
	},
	reactLogo: {
		height: 178,
		width: 290,
		bottom: 0,
		left: 0,
		position: "absolute",
	},
});
