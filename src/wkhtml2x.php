#!/usr/bin/env php
<?php

include_once './vendor/autoload.php';

define('WKHTMLTOPDF', '/usr/bin/wkhtmltopdf');
// define('WKHTMLTOIMAGE', '/usr/bin/wkhtmltoimage');

$http = new \Swoole\Http\Server('0.0.0.0', 80);

$http->on('request', function (\Swoole\Http\Request $request, \Swoole\Http\Response $response) {
    $uri = $request->server['path_info'];
    if ($uri == '/pdf') {
        try {
            $content = $request->post['file'] ?? '';
            if ($request->files['file'] ?? '') {
                $content = @file_get_contents($request->files['file']);
            }
            $url = $request->post['url'] ?? '';
            if (!$content && !$url) {
                throw new \Exception('没有需要转换的内容');
            }

            $snappy = new \Knp\Snappy\Pdf(WKHTMLTOPDF, $request->post['options'] ?? []);
            $response->header('Content-Type', 'application/pdf');
            if ($url) {
                $response->end($snappy->getOutput($url));
            } else {
                $response->end($snappy->getOutputFromHtml($content));
            }
        } catch (\Throwable $t) {
            $response->status(500);
            $response->end(str_replace('__ERROR__', $t->getMessage(), '<!DOCTYPE html><html><head><title>Internal Server Error</title></head><body><h1>Internal Server Error</h1><p>__ERROR__</p></body></html>'));
        }
    } else {
        $response->status(404);
        $response->end('<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1></body></html>');
    }
});

$http->start();