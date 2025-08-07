import { createSlice, PayloadAction } from "@reduxjs/toolkit";

interface AuthState {
	userName: string | null;
	isAuthenticated: boolean;
	token: string | null;
	isLoading: boolean;
	error: string | null;
}

const initialState: AuthState = {
	userName: null,
	isAuthenticated: false,
	token: null,
	isLoading: false,
	error: null,
};

const authSlice = createSlice({
	name: "auth",
	initialState,
	reducers: {
		authenticationSucceeded: (
			state,
			action: PayloadAction<Partial<AuthState>>,
		) => {
			state.isAuthenticated = action.payload.isAuthenticated!;
			state.token = action.payload.token!;
			state.userName = action.payload.userName!;
			state.isLoading = false;
			state.error = null;
		},
		authenticationLoaded: (state, action: PayloadAction<boolean>) => {
			state.isLoading = action.payload;
		},
		authenticationFailed: (state, action: PayloadAction<string>) => {
			state.error = action.payload;
			state.isLoading = false;
		},
		userLoggedOut: () => {
			return initialState;
		},
	},
	selectors: {
		selectCurrentToken: (x) => x.token,
		selectCurrentIsAuthenticated: (x) => x.isAuthenticated,
		selectCurrentUsername: (x) => x.userName,
	},
});

export const {
	authenticationSucceeded,
	authenticationLoaded,
	authenticationFailed,
	userLoggedOut,
} = authSlice.actions;

export const {
	selectCurrentToken,
	selectCurrentIsAuthenticated,
	selectCurrentUsername,
} = authSlice.selectors;

export default authSlice.reducer;
