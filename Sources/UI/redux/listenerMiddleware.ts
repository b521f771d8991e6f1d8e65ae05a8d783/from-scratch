import { addListener, createListenerMiddleware } from "@reduxjs/toolkit";
import type { AppDispatch, AppState } from "./store";

export const listenerMiddleware = createListenerMiddleware();

export const startAppListening = listenerMiddleware.startListening.withTypes<
	AppState,
	AppDispatch
>();
export type AppStartListening = typeof startAppListening;

export const addAppListener = addListener.withTypes<AppState, AppDispatch>();
export type AppAddListener = typeof addAppListener;
