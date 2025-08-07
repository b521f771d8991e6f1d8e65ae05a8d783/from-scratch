import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import { getBackendURL } from "../../config/appConfig";

export const apiSlice = createApi({
	reducerPath: "api",
	baseQuery: fetchBaseQuery({
		baseUrl: getBackendURL(),
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
	}),
});

export const { useGetBackendVersionQuery, useGetBackendStatusQuery } = apiSlice;
