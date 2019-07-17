<?php

/**
 * @file
 * The PHP page that serves all page requests on a Drupal installation.
 *
 * All Drupal code is released under the GNU General Public License.
 * See COPYRIGHT.txt and LICENSE.txt files in the "core" directory.
 */

use Drupal\Core\DrupalKernel;
use Symfony\Component\HttpFoundation\Request;

if (is_array($_SERVER) && array_key_exists('REQUEST_URI', $_SERVER) && ($_SERVER['REQUEST_URI'] === '/admin-on')) {
  setcookie('admin-mode', 'on', time() + 60 * 60 * 24 * 365);
  header('Location: ' . $_SERVER['REQUEST_SCHEME'] . '://' . $_SERVER['SERVER_NAME']);
  die();
}

if (is_array($_SERVER) && array_key_exists('REQUEST_URI', $_SERVER) && ($_SERVER['REQUEST_URI'] === '/admin-off')) {
  setcookie('admin-mode', null, -1);
  header('Location: ' . $_SERVER['REQUEST_SCHEME'] . '://' . $_SERVER['SERVER_NAME']);
  die();
}


$adminOn = false;

if (is_array($_COOKIE) && array_key_exists('admin-mode', $_COOKIE) && ($_COOKIE['admin-mode'] === 'on')) {
  $adminOn = true;
}


if ((is_array($_SERVER) && array_key_exists('HTTP_X_REQUESTED_WITH', $_SERVER) && ($_SERVER['HTTP_X_REQUESTED_WITH'] === 'webapp')) || $adminOn) {
  $autoloader = require_once 'autoload.php';

  $kernel = new DrupalKernel('prod', $autoloader);

  $request = Request::createFromGlobals();
  $response = $kernel->handle($request);
  $response->send();

  $kernel->terminate($request, $response);
} else {
  $indexContent = file_get_contents('index.html');
  echo $indexContent;
}


