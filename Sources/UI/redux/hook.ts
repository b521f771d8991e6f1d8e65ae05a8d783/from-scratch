// This file serves as a central hub for re-exporting pre-typed Redux hooks.
import { useDispatch, useSelector } from "react-redux";

import {
	selectCurrentIsAuthenticated,
	selectCurrentUsername,
} from "./state/authSlice.ts";
import type { AppDispatch, AppState } from "./store";

// Use throughout your app instead of plain `useDispatch` and `useSelector`
export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<AppState>();

// auth hooks
export const useAuthCurrentIsAuthenticatedSelector = () =>
	useAppSelector(selectCurrentIsAuthenticated);
export const useAuthCurrentUserNameSelector = () =>
	useAppSelector(selectCurrentUsername);
