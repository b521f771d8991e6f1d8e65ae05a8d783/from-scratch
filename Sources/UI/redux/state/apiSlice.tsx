import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import { Link } from "expo-router";
import { Text } from "react-native";
import { useGetPrivateBackendStatusQuery } from "./privateApiSlice";

export const apiSlice = createApi({
	reducerPath: "api",
	baseQuery: fetchBaseQuery({
		baseUrl: "/api",
	}),
	endpoints: (builder) => ({
		getBackendVersion: builder.query<string, void>({
			query: () => {
				return {
					url: "/version",
					method: "GET",
					responseHandler: (response) => response.text(),
				};
			},
		}),
		getBackendStatus: builder.query<boolean, void>({
			query: () => {
				return {
					url: "/status",
					method: "GET",
					responseHandler: (response) => response.text(),
				};
			},
			transformResponse: (response: string) => response === "👌",
		}),
		getAppConfig: builder.query<void, any>({
			query: () => {
				return {
					url: "/app-config.json",
				};
			},
		}),
	}),
});

export const {
	useGetBackendVersionQuery,
	useGetBackendStatusQuery,
	useGetAppConfigQuery,
} = apiSlice;

export function useGetDebugMode(): boolean {
	const { isSuccess: appConfigSuccess, currentData: appConfig } =
		useGetAppConfigQuery({});

	if (!appConfigSuccess || appConfig === undefined) {
		return false;
	} else {
		return "EXPO_PUBLIC_DEVELOPER_MODE" in appConfig;
	}
}

export function DebugControls() {
	const debugMode = useGetDebugMode();

	const { isLoading, isError, isSuccess, data } = useGetBackendStatusQuery();
	const {
		isLoading: privateIsLoading,
		isError: privateIsError,
		isSuccess: privateIsSuccess,
		data: privateData,
	} = useGetPrivateBackendStatusQuery();

	function getBackendStatus() {
		if (isLoading) {
			return <>...</>;
		} else if (isError) {
			return <>⛔</>;
		} else if (isSuccess) {
			return data ? "✅" : "⚠️";
		} else {
			return <>🚨</>;
		}
	}

	function getPrivateBackendStatus() {
		if (privateIsLoading) {
			return privateIsError;
		} else if (isError) {
			return <>⛔</>;
		} else if (privateIsSuccess) {
			return privateData ? "✅" : "⚠️";
		} else {
			return <>🚨</>;
		}
	}

	return (
		debugMode && (
			<>
				<Link href="/debugMode" className="self-center mt-4 underline">
					Debug-Modus 🪲
				</Link>
				<Text className="text-center">
					Backend Status: {getBackendStatus()}/{getPrivateBackendStatus()}
				</Text>{" "}
			</>
		)
	);
}
