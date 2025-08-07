import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import { getBackendURL } from "../../config/appConfig";
import { AppState } from "../store";
import { selectCurrentToken } from "./authSlice";

export const privateApiSlice = createApi({
	reducerPath: "api/private",
	baseQuery: fetchBaseQuery({
		baseUrl: getBackendURL() + "/private",
		prepareHeaders: (headers, { getState }) => {
			const token = selectCurrentToken(getState() as AppState);

			if (token) {
				headers.set("Authorization", `Bearer ${token}`);
			}

			return headers;
		},
	}),
	endpoints: (builder) => ({
		getPrivateBackendStatus: builder.query<boolean, void>({
			query: () => {
				return {
					url: "/status",
					method: "GET",
					responseHandler: (response) => response.text(),
				};
			},
			transformResponse: (response: string) => response === "👌",
		}),
	}),
});

export const { useGetPrivateBackendStatusQuery } = privateApiSlice;
