#!/usr/bin/env php
<?php

include_once './vendor/autoload.php';

define('WKHTMLTOPDF', __DIR__ . '/vendor/bin/wkhtmltopdf-amd64');
define('WKHTMLTOIMAGE', __DIR__ . '/vendor/bin/wkhtmltoimage-amd64');

$http = new \Swoole\Http\Server('0.0.0.0', 80);

$http->on('request', function (\Swoole\Http\Request $request, \Swoole\Http\Response $response) {
    $uri = $request->server['path_info'];
    if (in_array($uri, ['/pdf', '/image'])) {
        try {
            $content = $request->post['file'] ?? '';
            if ($request->files['file'] ?? '') {
                $content = @file_get_contents($request->files['file']);
            }
            if (!$content) {
                throw new \Exception('没有需要转换的内容');
            }

            if ($uri == '/pdf') {
                $snappy = new \Knp\Snappy\Pdf(WKHTMLTOPDF);
                $response->header('Content-Type', 'application/pdf');
            } else {
                $snappy = new \Knp\Snappy\Image(WKHTMLTOIMAGE);
                $response->header('Content-Type', 'image/jpeg');
            }
            $response->end($snappy->getOutputFromHtml($content));
        } catch (\Throwable $t) {
            $response->status(500);
            $response->end(str_replace('__ERROR__', $t->getMessage(), '<!DOCTYPE html><html><head><title>Internal Server Error</title></head><body><h1>Internal Server Error</h1><p>__ERROR__</p></body></html>'));
        }
    } else {
        $response->status(404);
            $response->end(str_replace('__ERROR__', $t->getMessage(), '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1><p>__ERROR__</p></body></html>'));
    }
});

$http->start();