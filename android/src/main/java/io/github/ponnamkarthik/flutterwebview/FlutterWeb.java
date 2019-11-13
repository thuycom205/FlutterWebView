package io.github.ponnamkarthik.flutterwebview;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import android.os.Handler;
import android.webkit.ValueCallback;


public class FlutterWeb implements PlatformView, MethodCallHandler {

    Context context;
    Registrar registrar;
    WebView webView;
    String url = "";
    MethodChannel channel;
    EventChannel.EventSink onPageFinishEvent;
    EventChannel.EventSink onPageStartEvent;
    EventChannel.EventSink onPageSuccessEvent;


    @SuppressLint("SetJavaScriptEnabled")
    FlutterWeb(Context context, Registrar registrar, int id) {
        this.context = context;
        this.registrar = registrar;
        this.url = url;
        webView = getWebView(registrar);

        channel = new MethodChannel(registrar.messenger(), "ponnamkarthik/flutterwebview_" + id);
        final EventChannel onPageFinishEvenetChannel = new EventChannel(registrar.messenger(), "ponnamkarthik/flutterwebview_stream_pagefinish_" + id);
        final EventChannel onPageStartEvenetChannel = new EventChannel(registrar.messenger(), "ponnamkarthik/flutterwebview_stream_pagestart_" + id);
        final EventChannel onpageSuccessEventChannel = new EventChannel(registrar.messenger(), "ponnamkarthik/my_second_event_channel_" + id);

        onPageFinishEvenetChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                onPageFinishEvent = eventSink;
            }

            @Override
            public void onCancel(Object o) {

            }
        });
        onPageStartEvenetChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                onPageStartEvent = eventSink;
            }

            @Override
            public void onCancel(Object o) {

            }
        });

        onpageSuccessEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                onPageSuccessEvent = eventSink;
            }

            @Override
            public void onCancel(Object o) {

            }
        });
        channel.setMethodCallHandler(this);
    }

    @Override
    public View getView() {
        return webView;
    }

    @Override
    public void dispose() {

    }

    private WebView getWebView(Registrar registrar) {
        WebView webView = new WebView(registrar.context());
        webView.setWebViewClient(new CustomWebViewClient());
        webView.getSettings().setJavaScriptEnabled(true);
        return webView;
    }



    private class CustomWebViewClient extends WebViewClient {
        public Handler handler  = null;
        final  Runnable runn = null;

        @SuppressWarnings("deprecated")
        @Override
        public boolean shouldOverrideUrlLoading(WebView wv, String url) {
            if (url.startsWith("http") || url.startsWith("https") || url.startsWith("ftp")) {
                return false;
            } else {
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                registrar.activity().startActivity(intent);
                return true;
            }
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            if(onPageStartEvent != null) {
                onPageStartEvent.success(url);
            }
            super.onPageStarted(view, url, favicon);
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            final  WebView viewx = view;
            final String urlx = url;
            if(onPageFinishEvent != null) {
                onPageFinishEvent.success(url);
                final Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        //Do something after 100ms
                        viewx.evaluateJavascript(
                                "(function() { return ('<html>'+document.getElementsByTagName('html')[0].innerHTML+'</html>'); })();",
                                new ValueCallback<String>() {
                                    @Override
                                    public void onReceiveValue(String html) {

                                        if (html.contains("thành công"))
                                            onPageSuccessEvent.success(urlx);
                                    }
                                });
                        handler.postDelayed(this, 2000);
                    }
                }, 1500);


            }
            super.onPageFinished(view, url);
        }


    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "loadUrl":
                String url = call.arguments.toString();
                webView.loadUrl(url);
                break;
            case "loadData":
                String html = call.arguments.toString();
                webView.loadDataWithBaseURL(null, html, "text/html", "utf-8",null);
                break;
            default:
                result.notImplemented();
        }

    }

}
