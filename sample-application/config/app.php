<?php
/*
*
 * Yii Application Config
 *
 * Edit this file at your own risk!
 *
 * The array returned by this file will get merged with
 * vendor/craftcms/cms/src/config/app.php and app.[web|console].php, when
 * Craft's bootstrap script is defining the configuration for the entire
 * application.
 *
 * You can define custom modules and system components, and even override the
 * built-in system components.
 *
 * If you want to modify the application config for *only* web requests or
 * *only* console requests, create an app.web.php or app.console.php file in
 * your config/ folder, alongside this one.
 *
 * Read more about application configuration:
 * https://craftcms.com/docs/4.x/config/app.html
 */

use craft\helpers\App;

return [
    'id' => App::env('CRAFT_APP_ID') ?: 'CraftCMS',
    'components' => [
        'cache' => function() {
            $config = [
                'class' => yii\redis\Cache::class,
                'keyPrefix' => Craft::$app->id,
                'defaultDuration' => Craft::$app->config->general->cacheDuration,

                'redis' => [
                    'hostname' => App::env('CRAFT_REDIS_ENDPOINT') ?: 'localhost',
                    'port' => 6379,
                    'password' => App::env('CRAFT_REDIS_PASSWORD') ?: null,
                    'database' => 0,
                ],
            ];

            return Craft::createObject($config);
        },
        'session' => function() {
            // Get the default component config:
            $config = craft\helpers\App::sessionConfig();

            // Replace component class:
            $config['class'] = yii\redis\Session::class;

            // Define additional properties:
            $config['redis'] = [
                'hostname' => App::env('CRAFT_REDIS_ENDPOINT') ?: 'localhost',
                'port' => 6379,
                'password' => App::env('CRAFT_REDIS_PASSWORD') ?: null,
                'database' => 1,
            ];

            // Return the initialized component:
            return Craft::createObject($config);
        }
    ],
];
