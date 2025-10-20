import { useGetAppConfigQuery } from "@/redux/state/apiSlice";
import {
	makeRedirectUri,
	useAuthRequest,
	useAutoDiscovery,
} from "expo-auth-session";
import { useEffect } from "react";
import { Button } from "react-native";

export function getCurrentToken(): string | undefined {
	return "";
}

export function LogInButton({
	setHasLoggedIn,
	hasLoggedIn,
}: {
	setHasLoggedIn: (arg0: boolean) => void;
	hasLoggedIn: boolean;
}) {
	const { isSuccess: appConfigSuccess, currentData: appConfig } =
		useGetAppConfigQuery({});

	function AuthWrapper({ appConfig }: { appConfig: any }) {
		const discovery = useAutoDiscovery(appConfig["EXPO_PUBLIC_OPENID_URL"]);
		const [request, response, promptAsync] = useAuthRequest(
			{
				clientId: "innovation-studio",
				scopes: [],
				redirectUri: makeRedirectUri({ path: "/internal/loginSuccess" }),
			},
			discovery!,
		);

		useEffect(() => {
			console.log(response);
		});

		return (
			<Button
				disabled={!request}
				title={hasLoggedIn ? "Angemeldet ✅" : "Anmelden 🔐"}
				onPress={() => {
					async function run() {
						const response = await promptAsync();

						switch (response.type) {
							case "success": {
								const auth = response.params;
								const storageValue = JSON.stringify(auth);

								console.log(storageValue);

								setHasLoggedIn(true);
								return;
							}
							default: {
								console.error("Error while opening browser", response);
								return;
							}
						}
					}

					run();
				}}
			/>
		);
	}

	return appConfigSuccess ? <AuthWrapper appConfig={appConfig} /> : <></>;
}
