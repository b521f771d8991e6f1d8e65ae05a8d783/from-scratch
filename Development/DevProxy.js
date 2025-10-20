import express from 'express';

import { createProxyMiddleware } from 'http-proxy-middleware';

const app = express();

const apiProxy = createProxyMiddleware({
    target: 'http://localhost:1334/api',
    changeOrigin: true,
});

const assetProxy = createProxyMiddleware({
    target: 'http://localhost:1334/assets',
    changeOrigin: true,
});

const otherProxy = createProxyMiddleware({
    target: 'http://localhost:8081',
    changeOrigin: true,
});

const unstablePathProxy = createProxyMiddleware({
    target: 'http://localhost:8081',
    changeOrigin: true,
});

// Proxy /api requests to 1334
app.use('/api', apiProxy);
app.use((req, res, next) => {
    if (req.query.unstable_path) {
        unstablePathProxy(req, res, next);
    } else {
        next();
    }
});
app.use('/assets', assetProxy);

// Proxy all other requests to 8081
app.use('/', otherProxy);


app.listen(3000);