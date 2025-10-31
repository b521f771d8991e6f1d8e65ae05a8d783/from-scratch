import { getCurrentToken } from "@/components/LogInButton";
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

export const privateApiSlice = createApi({
	reducerPath: "api/private",
	baseQuery: fetchBaseQuery({
		baseUrl: "/api/private",
		prepareHeaders: (headers) => {
			const token = getCurrentToken();

			if (token) {
				headers.set("Authorization", `Bearer ${token}`);
			} else {
				console.error("No authorization found")
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
