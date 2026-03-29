/**
 * OneSignal Web SDK v16 bridge for Flutter Web.
 * See: https://documentation.onesignal.com/docs/web-sdk-reference
 *
 * Debug: open Chrome DevTools → Console, filter by [ReNomada OneSignal]
 */
(function () {
  var LOG = '[ReNomada OneSignal]';

  function log() {
    var a = [LOG].concat(Array.prototype.slice.call(arguments));
    console.log.apply(console, a);
  }

  function warn() {
    var a = [LOG].concat(Array.prototype.slice.call(arguments));
    console.warn.apply(console, a);
  }

  window.OneSignalDeferred = window.OneSignalDeferred || [];

  /** Resolves when renomadaOneSignalInit's deferred callback has finished (on failure, cleared so init can retry). */
  var _initPromise = null;

  /**
   * @param {string} appId
   * @returns {Promise<void>}
   */
  window.renomadaOneSignalInit = function (appId) {
    if (_initPromise) {
      log('init: reusing existing init promise');
      return _initPromise;
    }
    _initPromise = new Promise(function (resolve, reject) {
      log('init queued, appId=', appId);
      log('browser origin (OneSignal Site URL must match this exactly):', window.location.origin);
      OneSignalDeferred.push(async function (OneSignal) {
        try {
          await OneSignal.init({
            appId: appId,
            allowLocalhostAsSecureOrigin: true,
            welcomeNotification: { disable: true },
          });
          log('init OK');

          try {
            if (typeof OneSignal.Notifications.isPushSupported === 'function') {
              log('isPushSupported=', OneSignal.Notifications.isPushSupported());
            }
          } catch (e) {
            warn('isPushSupported check failed', e);
          }

          OneSignal.Notifications.addEventListener('click', function (event) {
            try {
              var n = event.notification;
              var data = (n && n.additionalData) ? n.additionalData : {};
              if (window.renomadaOnOneSignalNotificationClick) {
                window.renomadaOnOneSignalNotificationClick(JSON.stringify(data));
              }
            } catch (e) {
              console.warn('OneSignal click handler', e);
            }
          });

          OneSignal.User.PushSubscription.addEventListener('change', function (ev) {
            try {
              var cur = ev && ev.current;
              var id = cur && cur.id;
              var optedIn = cur && cur.optedIn;
              log('PushSubscription change: id=', id, 'optedIn=', optedIn);
              if (id && window.renomadaOnOneSignalSubscriptionChange) {
                window.renomadaOnOneSignalSubscriptionChange(id);
              }
            } catch (e) {
              warn('subscription change handler', e);
            }
          });

          resolve();
        } catch (e) {
          warn('init FAILED', e);
          _initPromise = null;
          reject(e);
        }
      });
    });
    return _initPromise;
  };

  function sleep(ms) {
    return new Promise(function (r) { setTimeout(r, ms); });
  }

  /**
   * @param {string} externalId — Supabase auth user id (UUID)
   * @returns {Promise<string|null>}
   */
  window.renomadaOneSignalLogin = function (externalId) {
    return new Promise(function (resolve, reject) {
      if (!_initPromise) {
        warn('login FAILED: renomadaOneSignalInit was never called');
        reject(new Error('OneSignal init was not called'));
        return;
      }
      log('login queued, external_id (Supabase user)=', externalId);
      // Must not enqueue login until init's deferred callback has finished; otherwise
      // OneSignal._coreDirector is undefined and LoginManager throws (minified: reading 'Ye').
      _initPromise
        .then(function () {
          OneSignalDeferred.push(async function (OneSignal) {
            try {
              await OneSignal.login(externalId);
              try {
                log('after login: User.externalId=', OneSignal.User && OneSignal.User.externalId);
                log('after login: User.onesignalId=', OneSignal.User && OneSignal.User.onesignalId);
              } catch (e) {
                warn('could not read User ids', e);
              }

              await OneSignal.User.PushSubscription.optIn();
              log('optIn done');

              var permResult = null;
              try {
                if (typeof OneSignal.Notifications.requestPermission === 'function') {
                  permResult = await OneSignal.Notifications.requestPermission();
                }
              } catch (e) {
                warn('requestPermission error', e);
              }
              try {
                log('Notifications.permission=', OneSignal.Notifications.permission, 'requestPermission returned=', permResult);
              } catch (e) {}

              var id = null;
              for (var i = 0; i < 24; i++) {
                id = OneSignal.User.PushSubscription.id;
                if (id) break;
                await sleep(250);
              }
              try {
                var sub = OneSignal.User.PushSubscription;
                log('PushSubscription.id=', id, 'optedIn=', sub && sub.optedIn, 'token length=', (sub && sub.token && sub.token.length) || 0);
              } catch (e) {
                warn('could not read PushSubscription', e);
              }

              if (!id) {
                warn('No subscription id after login. User must click Allow in the browser prompt, and Site URL in OneSignal must match:', window.location.origin);
              } else {
                log('login flow OK, subscription id=', id);
              }
              resolve(id || null);
            } catch (e) {
              warn('login FAILED', e);
              reject(e);
            }
          });
        })
        .catch(function (e) {
          warn('login FAILED: init did not complete', e);
          reject(e);
        });
    });
  };

  /**
   * Best-effort logout. Never rejects (avoids breaking app sign-out if SDK/user state is incomplete).
   * @returns {Promise<void>}
   */
  window.renomadaOneSignalLogout = function () {
    return new Promise(function (resolve) {
      if (!_initPromise) {
        resolve();
        return;
      }
      _initPromise
        .then(function () {
          try {
            OneSignalDeferred.push(async function (OneSignal) {
              try {
                if (OneSignal && typeof OneSignal.logout === 'function') {
                  await OneSignal.logout();
                  log('logout OK');
                }
              } catch (e) {
                warn('logout skipped:', e);
              }
              resolve();
            });
          } catch (e) {
            console.warn('OneSignalDeferred logout enqueue failed:', e);
            resolve();
          }
        })
        .catch(function () {
          resolve();
        });
    });
  };
})();
