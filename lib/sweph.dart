// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'src/bindings.dart';
import 'src/utils.dart';
import 'src/ffi_proxy.dart';
import 'src/types.dart';

export 'src/types.dart';

/// Wrapper class for Sweph native binding, providing easy input/output
class Sweph {
  static const bundledEpheAssets = [
    "packages/sweph/assets/ephe/seas_18.se1",
    "packages/sweph/assets/ephe/semo_18.se1",
    "packages/sweph/assets/ephe/sepl_18.se1",
    "packages/sweph/assets/ephe/seasnam.txt",
    "packages/sweph/assets/ephe/sefstars.txt",
    "packages/sweph/assets/ephe/seleapsec.txt",
    "packages/sweph/assets/ephe/seorbel.txt"
  ];

  /// Platform-specific helpers
  static late AbstractPlatformProvider _provider;

  /// The bindings to the native functions in [_provider].lib.
  static late SwephBindings _bindings;

  /// Memory allocator
  static late Allocator _allocator;

  /// Initialize Sweph library and native bindings
  ///
  /// Should be called before any use of Sweph
  static init({List<String>? epheAssets}) async {
    _provider = await SwephPlatformProvider.instance;
    _allocator = _provider.allocator;
    _bindings = SwephBindings(_provider.lib);
    await _provider.saveEpheAssets(epheAssets);
    return using((Arena arena) {
      _bindings
          .swe_set_ephe_path(_provider.epheFilesPath.toNativeString(arena));
    }, _allocator);
  }

  static void registerWith(registrar) {
    // Ignore for Web
  }

  static DateTime _toDateTime(
      int year, int month, int day, int hour, int minute, double seconds) {
    int second = seconds.floor();
    seconds = (seconds - second) * 1000;
    int milliSecond = seconds.floor();
    seconds = (seconds - milliSecond) * 1000;
    int microSecond = seconds.floor();

    return DateTime.utc(
        year, month, day, hour, minute, second, milliSecond, microSecond);
  }

  static DateTime _toDateTime2(int year, int month, int day, double hours) {
    int hour = hours.floor();
    hours = (hours - hour) * 60;
    int minute = hours.floor();
    hours = (hours - minute) * 60;
    int second = hours.floor();
    hours = (hours - second) * 1000;
    int milliSecond = hours.floor();
    hours = (hours - milliSecond) * 1000;
    int microSecond = hours.floor();

    return DateTime.utc(
        year, month, day, hour, minute, second, milliSecond, microSecond);
  }

  // -----------------------------------------------------------------------------------------
  // Summary of SWISSEPH functions (https://www.astro.com/swisseph/swephprg.htm#_Toc78973625)
  // -----------------------------------------------------------------------------------------

  // -----------------------------------------------------------------
  // Calculation of planets and stars
  // Planets, moon, asteroids, lunar nodes, apogees, fictitious bodies
  // -----------------------------------------------------------------

  /// Calculates planetary positions from Universal Time (UT)
  ///
  /// [julianDay] Julian day number (in UT) for which the planetary positions are to be calculated
  /// [planet] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [CoordinatesWithSpeed]
  static CoordinatesWithSpeed swe_calc_ut(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc_ut(
        julianDay,
        planet.value,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
        coords[0],
        coords[1],
        coords[2],
        coords[3],
        coords[4],
        coords[5],
      );
    }, _allocator);
  }

  /// Calculates planetary positions from Terrestrial Time (TT)
  ///
  /// [julianDay] Julian day number (in TT)
  /// [planet] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [CoordinatesWithSpeed]
  static CoordinatesWithSpeed swe_calc(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc(
        julianDay,
        planet.value,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
        coords[0],
        coords[1],
        coords[2],
        coords[3],
        coords[4],
        coords[5],
      );
    }, _allocator);
  }

  /// Calculates planetocentric positions of planets, i. e. positions as
  /// observed from some different planet, e.g. Jupiter-centric ephemerides.
  /// The function can actually calculate any object as observed from any other
  /// object, e.g. also the position of some asteroid as observed from another
  /// asteroid or from a planetary moon.
  ///
  /// [julianDay] Julian day number (in TT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [center] HeavenlyBody from which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [CoordinatesWithSpeed]
  static CoordinatesWithSpeed swe_calc_pctr(double julianDay,
      HeavenlyBody target, HeavenlyBody center, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc_pctr(
        julianDay,
        target.value,
        center.value,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
        coords[0],
        coords[1],
        coords[2],
        coords[3],
        coords[4],
        coords[5],
      );
    }, _allocator);
  }

  /// Compute planetary nodes and apsides (perihelia, aphelia, second focal
  /// points of the orbital ellipses) from Universal Time (UT)
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [method] What kind of nodes or apsides are required
  ///
  /// Returns [NodesAndAspides]
  static NodesAndAspides swe_nod_aps_ut(double julianDay, HeavenlyBody target,
      SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_nod_aps_ut(
        julianDay,
        target.value,
        flags.value,
        method.value,
        nodesAsc,
        nodesDesc,
        perihelion,
        aphelion,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return NodesAndAspides(
        nodesAsc.toList(6),
        nodesDesc.toList(6),
        perihelion.toList(6),
        aphelion.toList(6),
      );
    }, _allocator);
  }

  /// Compute planetary nodes and apsides (perihelia, aphelia, second focal
  /// points of the orbital ellipses) from Terrestrial Time (TT)
  ///
  /// [julianDay] Julian day number (in TT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [method] What kind of nodes or apsides are required
  ///
  /// Returns [NodesAndAspides]
  static NodesAndAspides swe_nod_aps(double julianDay, HeavenlyBody target,
      SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_nod_aps(
        julianDay,
        target.value,
        flags.value,
        method.value,
        nodesAsc,
        nodesDesc,
        perihelion,
        aphelion,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return NodesAndAspides(
        nodesAsc.toList(6),
        nodesDesc.toList(6),
        perihelion.toList(6),
        aphelion.toList(6),
      );
    }, _allocator);
  }

  // -----------
  // Fixed stars
  // -----------

  /// Calculates positions of fixed stars from Universal Time (UT),
  /// faster function if many stars are calculated
  ///
  /// [star] Name of the star
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [StarInfo]
  static StarInfo swe_fixstar2_ut(
      String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result = _bindings.swe_fixstar2_ut(
        cstar,
        julianDay,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
        cstar.toDartString(),
        CoordinatesWithSpeed(
          coords[0],
          coords[1],
          coords[2],
          coords[3],
          coords[4],
          coords[5],
        ),
      );
    }, _allocator);
  }

  /// Calculates positions of fixed stars from Terrestrial Time (TT),
  /// faster function if many stars are calculated
  ///
  /// [star] Name of the star
  /// [julianDay] Julian day number (in TT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [StarInfo]
  static StarInfo swe_fixstar2(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result = _bindings.swe_fixstar2(
        cstar,
        julianDay,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
        cstar.toDartString(),
        CoordinatesWithSpeed(
          coords[0],
          coords[1],
          coords[2],
          coords[3],
          coords[4],
          coords[5],
        ),
      );
    }, _allocator);
  }

  /// Calculates positions of fixed stars from Universal Time (UT),
  /// faster function if single stars are calculated
  ///
  /// [star] Name of the star
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [StarInfo]
  static StarInfo swe_fixstar_ut(
      String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result = _bindings.swe_fixstar_ut(
        cstar,
        julianDay,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
        cstar.toDartString(),
        CoordinatesWithSpeed(
          coords[0],
          coords[1],
          coords[2],
          coords[3],
          coords[4],
          coords[5],
        ),
      );
    }, _allocator);
  }

  /// Calculates positions of fixed stars from Terrestrial Time (TT),
  /// faster function if single stars are calculated
  ///
  /// [star] Name of the star
  /// [julianDay] Julian day number (in TT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [StarInfo]
  static StarInfo swe_fixstar(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result = _bindings.swe_fixstar(
        cstar,
        julianDay,
        flags.value,
        coords,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
        cstar.toDartString(),
        CoordinatesWithSpeed(
          coords[0],
          coords[1],
          coords[2],
          coords[3],
          coords[4],
          coords[5],
        ),
      );
    }, _allocator);
  }

  /// get the magnitude of a fixed star
  ///
  /// [star] Name of the star
  ///
  /// Returns magnitude of the star
  static double swe_fixstar2_mag(String star) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar2_mag(star.toNativeString(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    }, _allocator);
  }

  /// get the magnitude of a fixed star (older method)
  ///
  /// [star] Name of the star
  ///
  /// Returns magnitude of the star
  static double swe_fixstar_mag(String star) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar_mag(star.toNativeString(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    }, _allocator);
  }

  /// Set the geographic location of observer for topocentric planet computation
  ///
  /// [geoLon] Longitude of observer
  /// [geoLat] Latitude of observer
  /// [geoalt] Altitude of observer (optional, default 0)
  static void swe_set_topo(double geoLon, double geoLat, [double geoalt = 0]) {
    _bindings.swe_set_topo(geoLon, geoLat, geoalt);
  }

  // ----------------------------------------------
  // Set the sidereal mode and get ayanamsha values
  // ----------------------------------------------

  /// Set the sidereal mode
  ///
  /// [mode] SiderealMode
  /// [flags] SiderealModeFlag (optional, default SE_SIDBIT_NONE)
  /// [t0] Starting point of ayanamsha measurement (optional, default 0)
  /// [ayan_t0] Starting point of ayanamsha measurement (optional, default 0)
  static void swe_set_sid_mode(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE,
      double t0 = 0,
      double ayan_t0 = 0]) {
    _bindings.swe_set_sid_mode((mode.value | flags.value), t0, ayan_t0);
  }

  /// Get ayanamsha for a given date in UT.
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns ayanamsha value
  static double swe_get_ayanamsa_ex_ut(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_get_ayanamsa_ex_ut(
          julianDay, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    }, _allocator);
  }

  /// Get ayanamsha for a given date in ET/TT.
  ///
  /// [julianDay] Julian day number (in ET/TT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns ayanamsha value
  static double swe_get_ayanamsa_ex(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_get_ayanamsa_ex(
          julianDay, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    }, _allocator);
  }

  /// Get ayanamsha for a given date in UT.
  /// Old function, better use swe_get_ayanamsa_ex
  ///
  /// [julianDay] Julian day number (in UT)
  ///
  /// Returns ayanamsha value
  static double swe_get_ayanamsa_ut(double julianDay) {
    return _bindings.swe_get_ayanamsa_ut(julianDay);
  }

  /// Get ayanamsha for a given date in ET/TT.
  /// Old function, better use swe_get_ayanamsa_ex
  ///
  /// [julianDay] Julian day number (in ET/TT)
  ///
  /// Returns ayanamsha value
  static double swe_get_ayanamsa(double julianDay) {
    return _bindings.swe_get_ayanamsa(julianDay);
  }

  /// Get the name of an ayanamsha for a given sidereal mode
  ///
  /// [mode] SiderealMode
  /// [flags] SiderealModeFlag (optional, default SE_SIDBIT_NONE)
  ///
  /// Returns name of the ayanamsha
  static String swe_get_ayanamsa_name(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE]) {
    return _bindings
        .swe_get_ayanamsa_name(mode.value | flags.value)
        .toDartString();
  }

  // --------------------------------
  // Eclipses and planetary phenomena
  // --------------------------------

  /// Find the next solar eclipse for a given geographic position
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoPos] Geographic position of observer
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_sol_eclipse_when_loc(double startJulianDay,
      SwephFlag flags, GeoPosition geoPos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attr = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_when_loc(
        startJulianDay,
        flags.value,
        geoPos.toNativeArray(arena),
        times,
        attr,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
        attributes: attr.toList(20),
      );
    }, _allocator);
  }

  /// Find the next solar eclipse globally
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [eclType] Type of eclipse
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_sol_eclipse_when_glob(double startJulianDay,
      SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_when_glob(
        startJulianDay,
        flags.value,
        eclType.value,
        times,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Compute the attributes of a solar eclipse
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoPos] Geographic position of observer
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_sol_eclipse_how(
      double julianDay, SwephFlag flags, GeoPosition geoPos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_how(
        julianDay,
        flags.value,
        geoPos.toNativeArray(arena),
        attributes,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Computes geographic location and attributes of solar eclipse
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_sol_eclipse_where(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geoPos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_where(
        julianDay,
        flags.value,
        geoPos,
        attributes,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        attributes: attributes.toList(20),
        geoPosition: GeoPosition(geoPos[0], geoPos[1]),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// find out the geographic position, where, for a given time, a central
  /// eclipse is central or where a non-central eclipse is maximal. With
  /// occultations, it tells us, at which geographic location the occulted body
  /// is in the middle of the lunar disc or closest to it. Because occultations
  /// are always visible from a very large area, this is not very interesting
  /// information. But it may become more interesting as soon as the limits of
  /// the umbra (and penumbra) will be implemented.
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] name of occulted star. Must be NULL or "", if a planetary
  /// occultation is to be calculated. For use of this field, see [swe_fixstar]
  /// [flags] ephemeris flag. If you want to have only one conjunction of the
  /// moon with the body tested, add the following flag: backward |= SE_ECL_ONE_TRY.
  /// If this flag is not set, the function will search for an occultation until
  /// it finds one. For bodies with ecliptical latitudes > 5, the function may
  /// search successlessly until it reaches the end of the ephemeris.
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_occult_where(
      double julianDay, HeavenlyBody target, String starname, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geoPos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_where(
        julianDay,
        target.value,
        starname.toNativeString(arena),
        flags.value,
        geoPos,
        attributes,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
        geoPosition: GeoPosition(geoPos[0], geoPos[1]),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Find the next occultation of a body by the moon for a given geographic position
  /// (can also be used for solar eclipses)
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] name of occulted star. Must be NULL or "", if a planetary
  /// occultation is to be calculated. For use of this field, see [swe_fixstar]
  /// [flags] ephemeris flag.
  /// [geoPos] Geographic position of observer
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_occult_when_loc(
      double startJulianDay,
      HeavenlyBody target,
      String starname,
      SwephFlag flags,
      GeoPosition geoPos,
      bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_when_loc(
        startJulianDay,
        target.value,
        starname.toNativeString(arena),
        flags.value,
        geoPos.toNativeArray(arena),
        times,
        attributes,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        attributes: attributes.toList(20),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Find the next occultation globally
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] name of occulted star. Must be NULL or "", if a planetary
  /// occultation is to be calculated. For use of this field, see [swe_fixstar]
  /// [flags] ephemeris flag.
  /// [eclType] Type of eclipse
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_occult_when_glob(
      double startJulianDay,
      HeavenlyBody target,
      String starname,
      SwephFlag flags,
      EclipseFlag eclType,
      bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_when_glob(
        startJulianDay,
        target.value,
        starname.toNativeString(arena),
        flags.value,
        eclType.value,
        times,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Find the next lunar eclipse observable from a geographic location
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoPos] Geographic position of observer
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_eclipse_when_loc(double startJulianDay,
      SwephFlag flags, GeoPosition geoPos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_when_loc(
        startJulianDay,
        flags.value,
        geoPos.toNativeArray(arena),
        times,
        attributes,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        attributes: attributes.toList(20),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Find the next lunar eclipse, global function
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [eclType] Type of eclipse
  /// [backward] Search backward from start date
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_eclipse_when(double startJulianDay,
      SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_when(
        startJulianDay,
        flags.value,
        eclType.value,
        times,
        backward.value,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Compute the attributes of a lunar eclipse at a given time
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoPos] Geographic position of observer
  ///
  /// Returns [EclipseInfo]
  static EclipseInfo swe_lun_eclipse_how(
      double julianDay, SwephFlag flags, GeoPosition geoPos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_how(
        julianDay,
        flags.value,
        geoPos.toNativeArray(arena),
        attributes,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
        eclipseType: EclipseFlag(result),
      );
    }, _allocator);
  }

  /// Compute risings, settings and meridian transits of a body
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] name of occulted star. Must be NULL or "", if a planetary
  /// occultation is to be calculated. For use of this field, see [swe_fixstar]
  /// [epheFlag] Ephemeris flags that indicate what kind of computation is wanted
  /// [rsmi] Rise/Set/Transit Flag
  /// [geoPos] Geographic position of observer
  /// [atPress] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atTemp] Atmospheric temperature at observer's location in degrees C
  ///
  /// returns:
  ///   0 if a rising, setting or transit event was found;
  ///  -1 if an error occurred (usually an ephemeris problem);
  ///  -2 if a rising or setting event was not found because the object is circumpolar.
  static double swe_rise_trans(
      double julianDay,
      HeavenlyBody target,
      String starname,
      SwephFlag epheFlag,
      RiseSetTransitFlag rsmi,
      GeoPosition geoPos,
      double atPress,
      double atTemp) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_rise_trans(
        julianDay,
        target.value,
        starname.toNativeString(arena),
        epheFlag.value,
        rsmi.value,
        geoPos.toNativeArray(arena),
        atPress,
        atTemp,
        times,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    }, _allocator);
  }

  /// Compute risings, settings and meridian transits of a body for a local
  /// horizon that has an altitude != 0
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] name of occulted star. Must be NULL or "", if a planetary
  /// occultation is to be calculated. For use of this field, see [swe_fixstar]
  /// [epheFlag] Ephemeris flags that indicate what kind of computation is wanted
  /// [rsmi] Rise/Set/Transit Flag
  /// [geoPos] Geographic position of observer
  /// [atPress] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atTemp] Atmospheric temperature at observer's location in degrees C
  /// [horHeight] Height of horizon in meters
  ///
  /// returns:
  ///   0 if a rising, setting or transit event was found;
  ///  -1 if an error occurred (usually an ephemeris problem);
  ///  -2 if a rising or setting event was not found because the object is circumpolar.
  static double swe_rise_trans_true_hor(
      double julianDay,
      HeavenlyBody target,
      String starname,
      SwephFlag epheFlag,
      RiseSetTransitFlag rsmi,
      GeoPosition geoPos,
      double atPress,
      double atTemp,
      double horHeight) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_rise_trans_true_hor(
        julianDay,
        target.value,
        starname.toNativeString(arena),
        epheFlag.value,
        rsmi.value,
        geoPos.toNativeArray(arena),
        atPress,
        atTemp,
        horHeight,
        times,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    }, _allocator);
  }

  /// Compute heliacal risings and settings and related phenomena
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [geoPos] Geographic position of observer
  /// [atm] Atmospheric conditions
  /// [obs] Observer conditions
  /// [name] Name of the star
  /// [eventType] Type of event
  /// [heliacalFlags] HeliacalFlags
  ///
  /// Returns a List<double> with the following data:
  ///  0: start visibility (Julian day number);
  ///  1: optimum visibility (Julian day number), zero if helFlag >= SE_HELFLAG_AV;
  ///  2: end of visibility (Julian day number), zero if helFlag >= SE_HELFLAG_AV.
  static List<double> swe_heliacal_ut(
      double startJulianDay,
      GeoPosition geoPos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType eventType,
      HeliacalFlags heliacalFlags) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_heliacal_ut(
        startJulianDay,
        geoPos.toNativeArray(arena),
        atm.toNativeArray(arena),
        obs.toNativeArray(arena),
        name.toNativeString(arena),
        eventType.value,
        heliacalFlags.value,
        values,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    }, _allocator);
  }

  /// Compute heliacal risings and settings and related phenomena
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [geoPos] Geographic position of observer
  /// [atm] Atmospheric conditions
  /// [obs] Observer conditions
  /// [name] Name of the star
  /// [eventType] Type of event
  /// [heliacalFlags] HeliacalFlags
  ///
  /// Returns a List<double> with the following data:
  ///   0=AltO        [deg]     topocentric altitude of object (unrefracted)
  ///   1=AppAltO     [deg]     apparent altitude of object (refracted)
  ///   2=GeoAltO     [deg]     geocentric altitude of object
  ///   3=AziO        [deg]     azimuth of object
  ///   4=AltS        [deg]     topocentric altitude of Sun
  ///   5=AziS        [deg]     azimuth of Sun
  ///   6=TAVact      [deg]     actual topocentric arcus visionis
  ///   7=ARCVact     [deg]     actual (geocentric) arcus visionis
  ///   8=DAZact      [deg]     actual difference between object's and sun's azimuth
  ///   9=ARCLact     [deg]     actual longitude difference between object and sun
  ///   10=kact       [-]       extinction coefficient
  ///   11=minTAV     [deg]     smallest topocentric arcus visionis
  ///   12=TfistVR    [JDN]     first time object is visible, according to VR
  ///   13=TbVR       [JDN      optimum time the object is visible, according to VR
  ///   14=TlastVR    [JDN]     last time object is visible, according to VR
  ///   15=TbYallop   [JDN]     best time the object is visible, according to Yallop
  ///   16=WMoon      [deg]     crescent width of Moon
  ///   17=qYal       [-]            q-test value of Yallop
  ///   18=qCrit      [-]            q-test criterion of Yallop
  ///   19=ParO       [deg]     parallax of object
  ///   20 Magn       [-]            magnitude of object
  ///   21=RiseO      [JDN]     rise/set time of object
  ///   22=RiseS      [JDN]     rise/set time of Sun
  ///   23=Lag        [JDN]     rise/set time of object minus rise/set time of Sun
  ///   24=TvisVR     [JDN]     visibility duration
  ///   25=LMoon      [deg]     crescent length of Moon
  ///   26=CVAact     [deg]
  ///   27=Illum      [%]            new
  ///   28=CVAact     [deg]     new
  ///   29=MSk        [-]
  static List<double> swe_heliacal_pheno_ut(
      double startJulianDay,
      GeoPosition geoPos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType eventType,
      HeliacalFlags heliacalFlags) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_heliacal_pheno_ut(
        startJulianDay,
        geoPos.toNativeArray(arena),
        atm.toNativeArray(arena),
        obs.toNativeArray(arena),
        name.toNativeString(arena),
        eventType.value,
        heliacalFlags.value,
        values,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    }, _allocator);
  }

  /// Determines the limiting visual magnitude in dark skies.
  ///
  /// [startJulianDay] start date for search, Jul. day UT
  /// [geoPos] Geographic position of observer
  /// [atm] Atmospheric conditions
  /// [obs] Observer conditions
  /// [name] Name of the star
  /// [heliacalFlags] HeliacalFlags
  ///
  /// Returns a [VisibilityInfo]
  static VisibilityInfo swe_vis_limit_mag(
      double startJulianDay,
      GeoPosition geoPos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalFlags heliacalFlags) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(8);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_vis_limit_mag(
        startJulianDay,
        geoPos.toNativeArray(arena),
        atm.toNativeArray(arena),
        obs.toNativeArray(arena),
        name.toNativeString(arena),
        heliacalFlags.value,
        values,
        error,
      );
      if (result == -1) {
        throw Exception(error.toDartString());
      }

      return VisibilityInfo(Visibility.fromInt(result), values.toList(8));
    }, _allocator);
  }

  /// Compute phase, phase angle, elongation, apparent diameter, apparent
  /// magnitude for the Sun, the Moon, all planets and asteroids for Universal
  /// Time (UT).
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns a List<double> with the following data:
  ///   0: phase angle (Earth-planet-sun)
  ///   1: phase (illumined fraction of disc)
  ///   2: elongation of planet
  ///   3: apparent diameter of disc
  ///   4: apparent magnitude
  static List<double> swe_pheno_ut(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_pheno_ut(
        julianDay,
        target.value,
        flags.value,
        attributes,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return attributes.toList(20);
    }, _allocator);
  }

  /// Compute phase, phase angle, elongation, apparent diameter, apparent
  /// magnitude for the Sun, the Moon, all planets and asteroids for Terrestrial
  /// Time (TT)
  ///
  /// [julianDay] Julian day number (in TT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns a List<double> with the following data:
  ///   0: phase angle (Earth-planet-sun)
  ///   1: phase (illumined fraction of disc)
  ///   2: elongation of planet
  ///   3: apparent diameter of disc
  ///   4: apparent magnitude
  static List<double> swe_pheno(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_pheno(
          julianDay, target.value, flags.value, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return attributes.toList(20);
    }, _allocator);
  }

  /// Computes the horizontal coordinates (azimuth and altitude) of a planet or
  /// a star from either ecliptical or equatorial coordinates.
  ///
  /// [julianDay] Julian day number (in UT)
  /// [azAltMode] azimuth/altitude mode
  /// [geoPos] Geographic position of observer
  /// [atPress] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atTemp] Atmospheric temperature at observer's location in degrees C
  /// [coord] Coordinates of the object
  ///
  /// Returns [AzimuthAltitudeInfo]
  static AzimuthAltitudeInfo swe_azalt(double julianDay, AzAltMode azAltMode,
      GeoPosition geoPos, double atPress, double atTemp, Coordinates coord) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(3);
      _bindings.swe_azalt(
        julianDay,
        azAltMode.value,
        geoPos.toNativeArray(arena),
        atPress,
        atTemp,
        coord.toNativeArray(arena),
        azAlt,
      );
      return AzimuthAltitudeInfo(azAlt[0], azAlt[1], azAlt[2]);
    }, _allocator);
  }

  /// Computes either ecliptical or equatorial coordinates from azimuth and true altitude.
  ///
  /// [julianDay] Julian day number (in UT)
  /// [azAltMode] azimuth/altitude mode
  /// [geoPos] Geographic position of observer
  /// [azimuth] Azimuth of the object
  /// [trueAltitude] True altitude of the object
  ///
  /// Returns [Coordinates]
  static Coordinates swe_azalt_rev(double julianDay, AzAltMode azAltMode,
      GeoPosition geoPos, double azimuth, double trueAltitude) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(2);
      Pointer<Double> coord = arena<Double>(2);
      azAlt[0] = azimuth;
      azAlt[1] = trueAltitude;
      _bindings.swe_azalt_rev(
        julianDay,
        azAltMode.value,
        geoPos.toNativeArray(arena),
        azAlt,
        coord,
      );
      return Coordinates(coord[0], coord[1], 0);
    }, _allocator);
  }

  /// Calculates either the true altitude from the apparent altitude
  /// or the apparent altitude from the apparent altitude.
  ///
  /// [altOfObject] Altitude of the object
  /// [atmPressure] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atmTemp] Atmospheric temperature at observer's location in degrees C
  /// [refracMode] Refraction mode
  ///
  /// Returns: [AltitudeRefracInfo]
  static AltitudeRefracInfo swe_refrac(double altOfObject, double atmPressure,
      double atmTemp, RefractionMode refracMode) {
    double calcAlt = _bindings.swe_refrac(
        altOfObject, atmPressure, atmTemp, refracMode.value);
    if (refracMode == RefractionMode.SE_TRUE_TO_APP) {
      return AltitudeRefracInfo(altOfObject, calcAlt);
    } else {
      return AltitudeRefracInfo(calcAlt, altOfObject);
    }
  }

  /// Calculates either the true altitude from the apparent altitude or the
  /// apparent altitude from the apparent altitude. allows correct calculation
  /// of refraction for altitudes above sea > 0, where the ideal horizon and
  /// planets that are visible may have a negative height.
  ///
  /// [altOfObject] Altitude of object above geometric horizon in degrees, where geometric horizon = plane perpendicular to gravity
  /// [altOfObserver] Altitude of observer above sea level in meters
  /// [atmPressure] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atmTemp] Atmospheric temperature at observer's location in degrees C
  /// [lapseRate] Lapse rate (dattemp/dgeoalt) = [°K/m]
  ///
  /// Returns: [AltitudeRefracInfo]
  static AltitudeRefracInfo swe_refrac_extended(
      double altOfObject,
      double altOfObserver,
      double atmPressure,
      double atmTemp,
      double lapseRate,
      RefractionMode refracMode) {
    return using((Arena arena) {
      Pointer<Double> values = arena<Double>(20);
      _bindings.swe_refrac_extended(
        altOfObject,
        altOfObserver,
        atmPressure,
        atmTemp,
        lapseRate,
        refracMode.value,
        values,
      );
      return AltitudeRefracInfo(values[0], values[1], values[2], values[3]);
    }, _allocator);
  }

  /// Sets the lapse rate for refraction calculations
  static void swe_set_lapse_rate(double lapseRate) {
    _bindings.swe_set_lapse_rate(lapseRate);
  }

  /// Calculates osculating elements (Kepler elements) and orbital periods for
  /// a planet, the Earth-Moon barycenter, or an asteroid.
  ///
  /// [julianDay] Julian day number (in ET/TT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns a List<double> with the following data:
  ///    0: semimajor axis (a)
  ///    1: eccentricity (e)
  ///    2: inclination (in)
  ///    3: longitude of ascending node (upper case omega OM)
  ///    4: argument of periapsis (lower case omega om)
  ///    5: longitude of periapsis (peri)
  ///    6: mean anomaly at epoch (M0)
  ///    7: true anomaly at epoch (N0)
  ///    8: eccentric anomaly at epoch (E0)
  ///    9: mean longitude at epoch (LM)
  ///   10: sidereal orbital period in tropical years
  ///   11: mean daily motion
  ///   12: tropical period in years
  ///   13: synodic period in days, negative, if inner planet (Venus, Mercury, Aten asteroids) or Moon
  ///   14: time of perihelion passage
  ///   15: perihelion distance
  ///   16: aphelion distance
  static List<double> swe_get_orbital_elements(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> values = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_get_orbital_elements(
        julianDay,
        target.value,
        flags.value,
        values,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return values.toList(50);
    }, _allocator);
  }

  /// Calculates the maximum possible distance, the minimum possible distance,
  /// and the current true distance of planet, the EMB, or an asteroid.
  ///
  /// [julianDay] Julian day number (in ET/TT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [OrbitalDistance]
  static OrbitalDistance swe_orbit_max_min_true_distance(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> dmax = arena<Double>();
      Pointer<Double> dmin = arena<Double>();
      Pointer<Double> dtrue = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_orbit_max_min_true_distance(
        julianDay,
        target.value,
        flags.value,
        dmax,
        dmin,
        dtrue,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return OrbitalDistance(dmax.value, dmin.value, dtrue.value);
    }, _allocator);
  }

  /// Delta T from Julian day number
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns delatT in seconds
  static double swe_deltat_ex(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      double delta = _bindings.swe_deltat_ex(julianDay, flags.value, error);
      return delta;
    }, _allocator);
  }

  /// Delta T from Julian day number
  ///
  /// [julianDay] Julian day number (in UT)
  ///
  /// Returns delatT in seconds
  static double swe_deltat(double julianDay) {
    return _bindings.swe_deltat(julianDay);
  }

  /// set a user defined delta t to be returned by functions swe_deltat() and swe_deltat_ex()
  ///
  /// [dt] delta t in seconds
  static void swe_set_delta_t_userdef(double dt) {
    _bindings.swe_set_delta_t_userdef(dt);
  }

  /// Julian day number from year, month, day, hour, with check whether date is legal
  ///
  /// [year] Year
  /// [month] Month
  /// [day] Day
  /// [hours] Hours
  /// [calType] Calendar type
  ///
  /// Returns Julian day number
  static double swe_date_conversion(
      int year, int month, int day, double hours, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_date_conversion(
        year,
        month,
        day,
        hours,
        (calType == CalendarType.SE_GREG_CAL ? 'g' : 'j').firstChar(),
        julianDay,
      );
      if (result < 0) {
        throw Exception("swe_date_conversion failed");
      }
      return julianDay.value;
    }, _allocator);
  }

  /// Julian day number from year, month, day, hour
  ///
  /// [year] Year
  /// [month] Month
  /// [day] Day
  /// [hours] Hours
  /// [calType] Calendar type
  ///
  /// Returns Julian day number
  static double swe_julday(
      int year, int month, int day, double hours, CalendarType calType) {
    return _bindings.swe_julday(year, month, day, hours, calType.value);
  }

  /// Year, month, day, hour from Julian day number
  ///
  /// [julianDay] Julian day number
  /// [calType] Calendar type
  ///
  /// Returns [DateTime]
  static DateTime swe_revjul(double julianDay, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int32> year = arena<Int32>();
      Pointer<Int32> month = arena<Int32>();
      Pointer<Int32> day = arena<Int32>();
      Pointer<Double> hours = arena<Double>();
      _bindings.swe_revjul(julianDay, calType.value, year, month, day, hours);
      return _toDateTime2(year.value, month.value, day.value, hours.value);
    }, _allocator);
  }

  /// Local time to UTC and UTC to local time
  ///
  /// [year] Year
  /// [month] Month
  /// [day] Day
  /// [hour] Hour
  /// [minute] Minute
  /// [seconds] Seconds
  /// [timezone] Timezone
  ///
  /// Returns [DateTime]
  static DateTime swe_utc_time_zone(int year, int month, int day, int hour,
      int minute, double seconds, double timezone) {
    return using((Arena arena) {
      Pointer<Int32> yearOut = arena<Int32>();
      Pointer<Int32> monthOut = arena<Int32>();
      Pointer<Int32> dayOut = arena<Int32>();
      Pointer<Int32> hourOut = arena<Int32>();
      Pointer<Int32> minuteOut = arena<Int32>();
      Pointer<Double> secondsOut = arena<Double>();
      _bindings.swe_utc_time_zone(
        year,
        month,
        day,
        hour,
        minute,
        seconds,
        timezone,
        yearOut,
        monthOut,
        dayOut,
        hourOut,
        minuteOut,
        secondsOut,
      );
      return _toDateTime(
        yearOut.value,
        monthOut.value,
        dayOut.value,
        hourOut.value,
        minuteOut.value,
        secondsOut.value,
      );
    }, _allocator);
  }

  /// UTC to julianDay (TT and UT1)
  ///
  /// [year] Year
  /// [month] Month
  /// [day] Day
  /// [hour] Hour
  /// [min] Minute
  /// [sec] Seconds
  /// [calType] Calendar type
  ///
  /// Returns a List<double> with the following data:
  ///  0: Julian day in ET (TT)
  ///  1: Julian day in UT (UT1)
  static List<double> swe_utc_to_jd(int year, int month, int day, int hour,
      int min, double sec, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Double> julianDays = arena<Double>(2);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_utc_to_jd(
        year,
        month,
        day,
        hour,
        min,
        sec,
        calType.value,
        julianDays,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDays.toList(2);
    }, _allocator);
  }

  /// TT (ET1) to UTC
  ///
  /// [julianDay] Julian day in ET (TT)
  /// [calType] Calendar type
  ///
  /// Returns [DateTime]
  static DateTime swe_jdet_to_utc(double julianDay, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int32> year = arena<Int32>();
      Pointer<Int32> mon = arena<Int32>();
      Pointer<Int32> day = arena<Int32>();
      Pointer<Int32> hour = arena<Int32>();
      Pointer<Int32> min = arena<Int32>();
      Pointer<Double> sec = arena<Double>();
      _bindings.swe_jdet_to_utc(
        julianDay,
        calType.value,
        year,
        mon,
        day,
        hour,
        min,
        sec,
      );
      return _toDateTime(
        year.value,
        mon.value,
        day.value,
        hour.value,
        min.value,
        sec.value,
      );
    }, _allocator);
  }

  /// UTC to TT (ET1)
  ///
  /// [julianDay] Julian day in UT (UT1)
  /// [calType] Calendar type
  ///
  /// Returns [DateTime]
  static DateTime swe_jdut1_to_utc(double julianDay, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int32> year = arena<Int32>();
      Pointer<Int32> mon = arena<Int32>();
      Pointer<Int32> day = arena<Int32>();
      Pointer<Int32> hour = arena<Int32>();
      Pointer<Int32> min = arena<Int32>();
      Pointer<Double> sec = arena<Double>();
      _bindings.swe_jdut1_to_utc(
        julianDay,
        calType.value,
        year,
        mon,
        day,
        hour,
        min,
        sec,
      );
      return _toDateTime(
        year.value,
        mon.value,
        day.value,
        hour.value,
        min.value,
        sec.value,
      );
    }, _allocator);
  }

  /// Get tidal acceleration used in swe_deltat()
  ///
  /// Returns tidal acceleration
  static double swe_get_tid_acc() {
    return _bindings.swe_get_tid_acc();
  }

  /// Set tidal acceleration to be used in swe_deltat()
  ///
  /// [tidalAcceleration] Tidal acceleration
  static void swe_set_tid_acc(double tidalAcceleration) {
    _bindings.swe_set_tid_acc(tidalAcceleration);
  }

  // ----------------
  // Equation of time
  // ----------------

  /// function returns the difference between local apparent and local mean time.
  /// e = LAT – LMT. tjd_et is ephemeris time
  ///
  /// [julianDay] Julian day number (in ET/TT)
  ///
  /// Returns the difference between local apparent and local mean time
  static double swe_time_equ(double julianDay) {
    return using((Arena arena) {
      Pointer<Double> timeDiff = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_time_equ(julianDay, timeDiff, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return timeDiff.value;
    }, _allocator);
  }

  /// converts Local Mean Time (LMT) to Local Apparent Time (LAT)
  ///
  /// [julianDayLmt] Julian day number (in ET/TT)
  /// [geoLon] Longitude of observer
  ///
  /// Returns Local Apparent Time (LAT)
  static double swe_lmt_to_lat(double julianDayLmt, double geoLon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLat = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result =
          _bindings.swe_lmt_to_lat(julianDayLmt, geoLon, julianDayLat, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLat.value;
    }, _allocator);
  }

  /// converts Local Apparent Time (LAT) to Local Mean Time (LMT)
  ///
  /// [julianDayLat] Julian day number (in ET/TT)
  /// [geoLon] Longitude of observer
  ///
  /// Returns Local Mean Time (LMT)
  static double swe_lat_to_lmt(double julianDayLat, double geoLon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLmt = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result =
          _bindings.swe_lat_to_lmt(julianDayLat, geoLon, julianDayLmt, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLmt.value;
    }, _allocator);
  }

  // --------------------------------------------
  // Initialization, setup, and closing functions
  // --------------------------------------------

  /// Set directory path of ephemeris files
  ///
  /// [epheFilesDir] Path to ephemeris files
  /// [forceOverwrite] Force overwrite of existing files
  static void swe_set_ephe_path(String? epheFilesDir,
      {bool forceOverwrite = false}) {
    if (kIsWeb || epheFilesDir == null) {
      return;
    }
    return using((Arena arena) {
      if (epheFilesDir != _provider.epheFilesPath) {
        _provider.copyEpheDir(epheFilesDir, forceOverwrite);
      }
    }, _allocator);
  }

  /// set file name of JPL file
  ///
  /// [filePath] Path to JPL file
  /// [forceOverwrite] Force overwrite of existing files
  static void swe_set_jpl_file(String filePath, {bool forceOverwrite = false}) {
    return using((Arena arena) {
      if (!kIsWeb) {
        _provider.copyEpheFile(filePath, forceOverwrite);
      }
      _bindings.swe_set_jpl_file(basename(filePath).toNativeString(arena));
    }, _allocator);
  }

  /// close Swiss Ephemeris library
  static void swe_close() {
    _bindings.swe_close();
  }

  /// find out version number of your Swiss Ephemeris
  ///
  /// Returns version number as String
  static String swe_version() {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_version(buffer);
      final ver = buffer.toDartString();
      return ver;
    }, _allocator);
  }

  /// find out the library path of the DLL or executable
  ///
  /// Returns library path as String
  static String swe_get_library_path() {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_get_library_path(buffer);
      final path = buffer.toDartString();
      return path;
    }, _allocator);
  }

  /// find out start and end date of *se1 ephemeris file after a call of swe_calc()
  ///
  /// [ifno] file number:
  ///    0: planet file sepl_xxx, used for Sun .. Pluto, or jpl file
  ///    1: moon file semo_xxx
  ///    2: main asteroid file seas_xxx  if such an object was computed
  ///    3: other asteroid or planetary moon file, if such object was computed
  ///    4: star file
  ///
  /// Returns [FileData]
  static FileData swe_get_current_file_data(int ifno) {
    return using((Arena arena) {
      Pointer<Double> tfstart = arena<Double>();
      Pointer<Double> tfend = arena<Double>();
      Pointer<Int32> denum = arena<Int32>();

      final path =
          _bindings.swe_get_current_file_data(ifno, tfstart, tfend, denum);
      return FileData(
        path.toDartString(),
        tfstart.value,
        tfend.value,
        denum.value,
      );
    }, _allocator);
  }

  // -----------------
  // House calculation
  // -----------------

  /// Sidereal time at the Greenwich Meridian, measured in hours, from julianDay in UT
  ///
  /// [julianDay] Julian day number (in UT)
  ///
  /// Returns sidereal time in hours
  static double swe_sidtime(double julianDay) {
    return _bindings.swe_sidtime(julianDay);
  }

  /// Sidereal time at the Greenwich Meridian, measured in hours, from julianDay in UT
  ///
  /// [julianDay] Julian day number (in UT)
  /// [eps] Obliquity of ecliptic in degrees
  /// [nut] Nutation in longitude in degrees
  ///
  /// Returns sidereal time in hours
  static double swe_sidtime0(double julianDay, double eps, double nut) {
    return _bindings.swe_sidtime0(julianDay, eps, nut);
  }

  /// Set the interpolation mode for the nutation calculations
  static void swe_set_interpolate_nut(bool do_interpolate) {
    _bindings.swe_set_interpolate_nut(do_interpolate.value);
  }

  /// Get name of a house method
  ///
  /// [hSys] House system
  ///
  /// Returns name of house system
  static String swe_house_name(Hsys hSys) {
    return using((Arena arena) {
      final result = _bindings.swe_house_name(hSys.value);
      return result.toDartString();
    }, _allocator);
  }

  /// Get house cusps, ascendant and MC
  ///
  /// [julianDay] Julian day number (in UT)
  /// [geoLat] Latitude of observer
  /// [geoLon] Longitude of observer
  /// [hSys] House system
  ///
  /// Returns [HouseCuspData]
  static HouseCuspData swe_houses(
      double julianDay, double geoLat, double geoLon, Hsys hSys) {
    final cuspsSize = hSys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses(julianDay, geoLat, geoLon, hSys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.toList(cuspsSize),
        ascmc.toList(10),
      );
    }, _allocator);
  }

  /// compute tropical or sidereal positions
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoLat] Latitude of observer
  /// [geoLon] Longitude of observer
  /// [hSys] House system
  ///
  /// Returns [HouseCuspData]
  static HouseCuspData swe_houses_ex(double julianDay, SwephFlag flags,
      double geoLat, double geoLon, Hsys hSys) {
    final cuspsSize = hSys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses_ex(
          julianDay, flags.value, geoLat, geoLon, hSys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.toList(cuspsSize),
        ascmc.toList(10),
      );
    }, _allocator);
  }

  /// compute tropical or sidereal positions with speeds
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [geoLat] Latitude of observer
  /// [geoLon] Longitude of observer
  /// [hSys] House system
  ///
  /// Returns [HouseCuspData]
  static HouseCuspData swe_houses_ex2(double julianDay, SwephFlag flags,
      double geoLat, double geoLon, Hsys hSys) {
    final cuspsSize = hSys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_houses_ex2(
        julianDay,
        flags.value,
        geoLat,
        geoLon,
        hSys.value,
        cusps,
        ascmc,
        cuspsSpeed,
        ascmcSpeed,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return HouseCuspData(
        cusps.toList(cuspsSize),
        ascmc.toList(10),
        cuspsSpeed.toList(cuspsSize),
        ascmcSpeed.toList(10),
      );
    }, _allocator);
  }

  /// compute tropical or sidereal positions when a sidereal time [armc] is given but no actual date is known
  ///
  /// [armc] Sidereal time
  /// [geoLat] Latitude of observer
  /// [eps] Obliquity of ecliptic in degrees
  /// [hSys] House system
  ///
  /// Returns [HouseCuspData]
  static HouseCuspData swe_houses_armc(
      double armc, double geoLat, double eps, Hsys hSys) {
    final cuspsSize = hSys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses_armc(armc, geoLat, eps, hSys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.toList(cuspsSize),
        ascmc.toList(10),
      );
    }, _allocator);
  }

  /// compute tropical or sidereal positions with speeds when a sidereal time [armc] is given but no actual date is known
  ///
  /// [armc] Sidereal time
  /// [geoLat] Latitude of observer
  /// [eps] Obliquity of ecliptic in degrees
  /// [hSys] House system
  ///
  /// Returns [HouseCuspData]
  static HouseCuspData swe_houses_armc_ex2(
      double armc, double geoLat, double eps, Hsys hSys) {
    final cuspsSize = hSys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_houses_armc_ex2(
        armc,
        geoLat,
        eps,
        hSys.value,
        cusps,
        ascmc,
        cuspsSpeed,
        ascmcSpeed,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return HouseCuspData(
        cusps.toList(cuspsSize),
        ascmc.toList(10),
        cuspsSpeed.toList(cuspsSize),
        ascmcSpeed.toList(10),
      );
    }, _allocator);
  }

  /// Get the house position of a celestial point
  ///
  /// [armc] Sidereal time
  /// [geoLat] Latitude of observer
  /// [eps] Obliquity of ecliptic in degrees
  /// [hSys] House system
  ///
  /// Returns [HousePosition]
  static HousePosition swe_house_pos(
      double armc, double geoLat, double eps, Hsys hSys) {
    return using((Arena arena) {
      Pointer<Double> position = arena<Double>(2);
      Pointer<Uint8> error = arena<Uint8>(256);
      final pos = _bindings.swe_house_pos(
        armc,
        geoLat,
        eps,
        hSys.value,
        position,
        error,
      );
      if (pos < 0) {
        throw Exception(error.toDartString());
      }
      return HousePosition(position[0], position[1], pos);
    }, _allocator);
  }

  /// Get the Gauquelin sector position for a body
  ///
  /// [julianDay] Julian day number (in UT)
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [starname] Name of star
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [method] Method of computation
  /// [geoPos] Geographical position of observer
  /// [atPress] Atmospheric pressure at observer's location in millibars (hPa)
  /// [atTemp] Atmospheric temperature at observer's location in degrees Celsius
  ///
  /// Returns Gauquelin sector position
  static double swe_gauquelin_sector(
      double julianDay,
      int target,
      String starname,
      SwephFlag flags,
      GauquelinMethod method,
      GeoPosition geoPos,
      double atPress,
      double atTemp) {
    return using((Arena arena) {
      Pointer<Double> gsect = arena<Double>(2);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_gauquelin_sector(
        julianDay,
        target,
        starname.toNativeString(arena),
        flags.value,
        method.value,
        geoPos.toNativeArray(arena),
        atPress,
        atTemp,
        gsect,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return gsect.value;
    }, _allocator);
  }

  // -----------------------------------------------------
  // Functions to find crossings of planets over positions
  // -----------------------------------------------------

  /// find the crossing of the Sun over a given ecliptic position at [julianDay] in ET
  ///
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in ET)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns Julian day number of crossing
  static double swe_solcross(
      double x2cross, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDayCalc =
          _bindings.swe_solcross(x2cross, julianDay, flags.value, error);
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc;
    }, _allocator);
  }

  /// find the crossing of the Sun over a given ecliptic position at [julianDay] in UT
  ///
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns Julian day number of crossing
  static double swe_solcross_ut(
      double x2cross, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDayCalc =
          _bindings.swe_solcross_ut(x2cross, julianDay, flags.value, error);
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc;
    }, _allocator);
  }

  /// find the crossing of the Moon over a given ecliptic position at [julianDay] in ET
  ///
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in ET)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns Julian day number of crossing
  static double swe_mooncross(
      double x2cross, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDayCalc =
          _bindings.swe_mooncross(x2cross, julianDay, flags.value, error);
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc;
    }, _allocator);
  }

  /// find the crossing of the Moon over a given ecliptic position at [julianDay] in UT
  ///
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns Julian day number of crossing
  static double swe_mooncross_ut(
      double x2cross, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDayCalc =
          _bindings.swe_mooncross_ut(x2cross, julianDay, flags.value, error);
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc;
    }, _allocator);
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [julianDay] in ET
  ///
  /// [julianDay] Julian day number (in ET)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [CrossingInfo]
  static CrossingInfo swe_mooncross_node(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> xlon = arena<Double>();
      Pointer<Double> xlat = arena<Double>();
      final julianDayCalc = _bindings.swe_mooncross_node(
          julianDay, flags.value, xlon, xlat, error);
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return CrossingInfo(
        julianDayCalc,
        xlon.value,
        xlat.value,
      );
    }, _allocator);
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [julianDay] in UT
  ///
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  ///
  /// Returns [CrossingInfo]
  static CrossingInfo swe_mooncross_node_ut(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> xlon = arena<Double>();
      Pointer<Double> xlat = arena<Double>();
      final julianDayCalc = _bindings.swe_mooncross_node_ut(
        julianDay,
        flags.value,
        xlon,
        xlat,
        error,
      );
      if (julianDayCalc < julianDay) {
        throw Exception(error.toDartString());
      }
      return CrossingInfo(
        julianDayCalc,
        xlon.value,
        xlat.value,
      );
    }, _allocator);
  }

  /// heliocentric crossings over a position [x2cross] at [julianDay] in ET
  ///
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in ET)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [dir] Direction of crossing
  ///
  /// Returns Julian day number of crossing
  static double swe_helio_cross(HeavenlyBody target, double x2cross,
      double julianDay, SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> julianDayCalc = arena<Double>();
      final result = _bindings.swe_helio_cross(
        target.value,
        x2cross,
        julianDay,
        flags.value,
        dir,
        julianDayCalc,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc.value;
    }, _allocator);
  }

  /// heliocentric crossings over a position [x2cross] at [julianDay] in UT
  ///
  /// [target] HeavenlyBody for which the position is to be calculated
  /// [x2cross] Ecliptic position
  /// [julianDay] Julian day number (in UT)
  /// [flags] Ephemeris flags that indicate what kind of computation is wanted
  /// [dir] Direction of crossing
  ///
  /// Returns Julian day number of crossing
  static double swe_helio_cross_ut(HeavenlyBody target, double x2cross,
      double julianDay, SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> julianDayCalc = arena<Double>();
      final result = _bindings.swe_helio_cross_ut(
        target.value,
        x2cross,
        julianDay,
        flags.value,
        dir,
        julianDayCalc,
        error,
      );
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayCalc.value;
    }, _allocator);
  }

  // -------------------
  // Auxiliary functions
  // -------------------

  /// coordinate transformation, from ecliptic to equator or vice-versa
  ///
  /// [coordinates] Coordinates to be transformed
  /// [eps] Obliquity of ecliptic in degrees
  ///
  /// Returns [Coordinates]
  static Coordinates swe_cotrans(Coordinates coordinates, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(3);
      _bindings.swe_cotrans(coordinates.toNativeArray(arena), xpn, eps);
      return Coordinates(xpn[0], xpn[1], xpn[2]);
    }, _allocator);
  }

  /// coordinate transformation of position and speed, from ecliptic to equator or vice-versa
  ///
  /// [xpo] 6 doubles, input: long., lat., dist. and speeds in long., lat and dist.
  /// [eps] Obliquity of ecliptic in degrees
  ///
  /// Returns [CoordinatesWithSpeed]
  static CoordinatesWithSpeed swe_cotrans_sp(List<double> xpo, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(6);
      _bindings.swe_cotrans_sp(xpo.toNativeString(arena), xpn, eps);
      return CoordinatesWithSpeed(
          xpn[0], xpn[1], xpn[2], xpn[3], xpn[4], xpn[5]);
    }, _allocator);
  }

  /// get the name of a planet
  ///
  /// [planet] Planet for which the name is to be retrieved
  ///
  /// Returns name of planet
  static String swe_get_planet_name(HeavenlyBody planet) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_get_planet_name(planet.value, buffer);
      final name = buffer.toDartString();
      return name;
    }, _allocator);
  }

  /// normalize degrees to the range 0 ... 360
  ///
  /// [degrees] Degrees to be normalized
  ///
  /// Returns normalized degrees
  static double swe_degnorm(double degrees) {
    return _bindings.swe_degnorm(degrees);
  }

  /// normalize radians to the range 0 ... 2 PI
  ///
  /// [radians] Radians to be normalized
  ///
  /// Returns normalized radians
  static double swe_radnorm(double radians) {
    return _bindings.swe_radnorm(radians);
  }

  /// Radians midpoint
  ///
  /// [rad1] First radian
  /// [rad2] Second radian
  ///
  /// Returns midpoint in radians
  static double swe_rad_midp(double rad1, double rad2) {
    return _bindings.swe_rad_midp(rad1, rad2);
  }

  /// Degrees midpoint
  ///
  /// [deg1] First degree
  /// [deg2] Second degree
  ///
  /// Returns midpoint in degrees
  static double swe_deg_midp(double deg1, double deg2) {
    return _bindings.swe_deg_midp(deg1, deg2);
  }

  /// split degrees in centiseconds to sign/nakshatra, degrees, minutes, seconds of arc
  ///
  /// [deg] Degrees to be split
  /// [roundflag] Round flag
  ///
  /// Returns [DegreeSplitData]
  static DegreeSplitData swe_split_deg(double deg, SplitDegFlags roundflag) {
    return using((Arena arena) {
      Pointer<Int32> splitDeg = arena<Int32>();
      Pointer<Int32> splitMin = arena<Int32>();
      Pointer<Int32> splitSec = arena<Int32>();
      Pointer<Double> splitSecOfArc = arena<Double>();
      Pointer<Int32> splitSgn = arena<Int32>();
      _bindings.swe_split_deg(
        deg,
        roundflag.value,
        splitDeg,
        splitMin,
        splitSec,
        splitSecOfArc,
        splitSgn,
      );
      return DegreeSplitData(
        splitDeg.value,
        splitMin.value,
        splitSec.value,
        splitSecOfArc.value,
        splitSgn.value,
      );
    }, _allocator);
  }

  // ----------------------------------
  // Other functions that may be useful
  // ----------------------------------

  /// Normalize argument into interval [0..DEG360]
  ///
  /// [deg] Degrees to be normalized
  ///
  /// Returns normalized degrees as [Centisec]
  static Centisec swe_csnorm(Centisec deg) {
    return _bindings.swe_csnorm(deg);
  }

  /// Distance in centisecs p1 - p2 normalized to [0..360]
  ///
  /// [p1] First centisecond
  /// [p2] Second centisecond
  ///
  /// Returns distance in centiseconds
  static Centisec swe_difcsn(Centisec p1, Centisec p2) {
    return _bindings.swe_difcsn(p1, p2);
  }

  /// Distance in degrees
  ///
  /// [p1] First degree
  /// [p2] Second degree
  ///
  /// Returns distance in degrees
  double swe_difdegn(double p1, double p2) {
    return _bindings.swe_difdegn(p1, p2);
  }

  /// Distance in centisecs p1 - p2 normalized to [-180..180]
  ///
  /// [p1] First centisecond
  /// [p2] Second centisecond
  ///
  /// Returns distance in [Centisec]
  static Centisec swe_difcs2n(Centisec p1, Centisec p2) {
    return _bindings.swe_difcs2n(p1, p2);
  }

  /// Distance in degrees
  ///
  /// [p1] First degree
  /// [p2] Second degree
  ///
  /// Returns distance in degrees
  double swe_difdeg2n(double p1, double p2) {
    return _bindings.swe_difdeg2n(p1, p2);
  }

  /// Round second, but at 29.5959 always down
  ///
  /// [deg] Degrees to be rounded
  ///
  /// Returns rounded degrees as [Centisec]
  static Centisec swe_csroundsec(Centisec deg) {
    return _bindings.swe_csroundsec(deg);
  }

  /// Double to long with rounding, no overflow check
  ///
  /// [x] Double to be rounded
  ///
  /// Returns rounded double as [Int32]
  static int swe_d2l(double x) {
    return _bindings.swe_d2l(x);
  }

  /// Day of week Monday = 0, ... Sunday = 6
  ///
  /// [julianDay] Julian day number (in UT)
  ///
  /// Returns day of week
  static int swe_day_of_week(double julianDay) {
    return _bindings.swe_day_of_week(julianDay);
  }

  /// Centiseconds -> time string
  ///
  /// [deg] Centiseconds
  /// [sep] Separator
  /// [suppressZero] Suppress zero
  ///
  /// Returns time string
  static String swe_cs2timestr(Centisec deg, int sep, bool suppressZero) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(10);
      _bindings.swe_cs2timestr(deg, sep, suppressZero.value, buffer);
      return buffer.toDartString();
    }, _allocator);
  }

  /// Centiseconds -> longitude or latitude string
  ///
  /// [deg] Centiseconds
  /// [pchar] Positive character
  /// [mchar] Negative character
  ///
  /// Returns longitude or latitude string
  static String swe_cs2lonlatstr(Centisec deg, String pchar, String mchar) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(12);
      _bindings.swe_cs2lonlatstr(
          deg, pchar.firstChar(), mchar.firstChar(), buffer);
      return buffer.toDartString();
    }, _allocator);
  }

  /// Centiseconds -> degrees string
  ///
  /// [deg] Centiseconds
  ///
  /// Returns degrees string
  static String swe_cs2degstr(Centisec deg) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(10);
      _bindings.swe_cs2degstr(deg, buffer);
      return buffer.toDartString();
    }, _allocator);
  }
}
