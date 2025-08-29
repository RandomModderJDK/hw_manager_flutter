// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _3: (o, t) => typeof o === t,
      _4: (o, c) => o instanceof c,
      _7: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._7(f,arguments.length,x0) }),
      _8: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._8(f,arguments.length,x0,x1) }),
      _37: x0 => new Array(x0),
      _39: x0 => x0.length,
      _41: (x0,x1) => x0[x1],
      _42: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _87: x0 => x0.click(),
      _88: x0 => x0.buffer,
      _89: x0 => x0.wasmMemory,
      _90: () => globalThis.window._flutter_skwasmInstance,
      _91: x0 => x0.rasterStartMilliseconds,
      _92: x0 => x0.rasterEndMilliseconds,
      _93: x0 => x0.imageBitmaps,
      _120: x0 => x0.remove(),
      _121: (x0,x1) => x0.append(x1),
      _122: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _123: (x0,x1) => x0.querySelector(x1),
      _125: (x0,x1) => x0.removeChild(x1),
      _203: x0 => x0.stopPropagation(),
      _204: x0 => x0.preventDefault(),
      _206: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _251: x0 => x0.unlock(),
      _252: x0 => x0.getReader(),
      _253: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _254: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _255: (x0,x1) => x0.item(x1),
      _256: x0 => x0.next(),
      _257: x0 => x0.now(),
      _258: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._258(f,arguments.length,x0) }),
      _259: (x0,x1) => x0.addListener(x1),
      _260: (x0,x1) => x0.removeListener(x1),
      _261: (x0,x1) => x0.matchMedia(x1),
      _262: (x0,x1) => x0.revokeObjectURL(x1),
      _263: x0 => x0.close(),
      _264: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _265: x0 => new window.ImageDecoder(x0),
      _266: x0 => ({frameIndex: x0}),
      _267: (x0,x1) => x0.decode(x1),
      _268: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._268(f,arguments.length,x0) }),
      _269: (x0,x1) => x0.getModifierState(x1),
      _270: (x0,x1) => x0.removeProperty(x1),
      _271: (x0,x1) => x0.prepend(x1),
      _272: x0 => x0.disconnect(),
      _273: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._273(f,arguments.length,x0) }),
      _274: (x0,x1) => x0.getAttribute(x1),
      _275: (x0,x1) => x0.contains(x1),
      _276: x0 => x0.blur(),
      _277: x0 => x0.hasFocus(),
      _278: (x0,x1) => x0.hasAttribute(x1),
      _279: (x0,x1) => x0.getModifierState(x1),
      _280: (x0,x1) => x0.appendChild(x1),
      _281: (x0,x1) => x0.createTextNode(x1),
      _282: (x0,x1) => x0.removeAttribute(x1),
      _283: x0 => x0.getBoundingClientRect(),
      _284: (x0,x1) => x0.observe(x1),
      _285: x0 => x0.disconnect(),
      _286: (x0,x1) => x0.closest(x1),
      _696: () => globalThis.window.flutterConfiguration,
      _697: x0 => x0.assetBase,
      _703: x0 => x0.debugShowSemanticsNodes,
      _704: x0 => x0.hostElement,
      _705: x0 => x0.multiViewEnabled,
      _706: x0 => x0.nonce,
      _708: x0 => x0.fontFallbackBaseUrl,
      _712: x0 => x0.console,
      _713: x0 => x0.devicePixelRatio,
      _714: x0 => x0.document,
      _715: x0 => x0.history,
      _716: x0 => x0.innerHeight,
      _717: x0 => x0.innerWidth,
      _718: x0 => x0.location,
      _719: x0 => x0.navigator,
      _720: x0 => x0.visualViewport,
      _721: x0 => x0.performance,
      _723: x0 => x0.URL,
      _725: (x0,x1) => x0.getComputedStyle(x1),
      _726: x0 => x0.screen,
      _727: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._727(f,arguments.length,x0) }),
      _728: (x0,x1) => x0.requestAnimationFrame(x1),
      _733: (x0,x1) => x0.warn(x1),
      _735: (x0,x1) => x0.debug(x1),
      _736: x0 => globalThis.parseFloat(x0),
      _737: () => globalThis.window,
      _738: () => globalThis.Intl,
      _739: () => globalThis.Symbol,
      _740: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _742: x0 => x0.clipboard,
      _743: x0 => x0.maxTouchPoints,
      _744: x0 => x0.vendor,
      _745: x0 => x0.language,
      _746: x0 => x0.platform,
      _747: x0 => x0.userAgent,
      _748: (x0,x1) => x0.vibrate(x1),
      _749: x0 => x0.languages,
      _750: x0 => x0.documentElement,
      _751: (x0,x1) => x0.querySelector(x1),
      _754: (x0,x1) => x0.createElement(x1),
      _757: (x0,x1) => x0.createEvent(x1),
      _758: x0 => x0.activeElement,
      _761: x0 => x0.head,
      _762: x0 => x0.body,
      _764: (x0,x1) => { x0.title = x1 },
      _767: x0 => x0.visibilityState,
      _768: () => globalThis.document,
      _769: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._769(f,arguments.length,x0) }),
      _770: (x0,x1) => x0.dispatchEvent(x1),
      _778: x0 => x0.target,
      _780: x0 => x0.timeStamp,
      _781: x0 => x0.type,
      _783: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _790: x0 => x0.firstChild,
      _794: x0 => x0.parentElement,
      _796: (x0,x1) => { x0.textContent = x1 },
      _797: x0 => x0.parentNode,
      _799: x0 => x0.isConnected,
      _803: x0 => x0.firstElementChild,
      _805: x0 => x0.nextElementSibling,
      _806: x0 => x0.clientHeight,
      _807: x0 => x0.clientWidth,
      _808: x0 => x0.offsetHeight,
      _809: x0 => x0.offsetWidth,
      _810: x0 => x0.id,
      _811: (x0,x1) => { x0.id = x1 },
      _814: (x0,x1) => { x0.spellcheck = x1 },
      _815: x0 => x0.tagName,
      _816: x0 => x0.style,
      _818: (x0,x1) => x0.querySelectorAll(x1),
      _819: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _820: x0 => x0.tabIndex,
      _821: (x0,x1) => { x0.tabIndex = x1 },
      _822: (x0,x1) => x0.focus(x1),
      _823: x0 => x0.scrollTop,
      _824: (x0,x1) => { x0.scrollTop = x1 },
      _825: x0 => x0.scrollLeft,
      _826: (x0,x1) => { x0.scrollLeft = x1 },
      _827: x0 => x0.classList,
      _829: (x0,x1) => { x0.className = x1 },
      _831: (x0,x1) => x0.getElementsByClassName(x1),
      _832: (x0,x1) => x0.attachShadow(x1),
      _835: x0 => x0.computedStyleMap(),
      _836: (x0,x1) => x0.get(x1),
      _842: (x0,x1) => x0.getPropertyValue(x1),
      _843: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _844: x0 => x0.offsetLeft,
      _845: x0 => x0.offsetTop,
      _846: x0 => x0.offsetParent,
      _848: (x0,x1) => { x0.name = x1 },
      _849: x0 => x0.content,
      _850: (x0,x1) => { x0.content = x1 },
      _854: (x0,x1) => { x0.src = x1 },
      _855: x0 => x0.naturalWidth,
      _856: x0 => x0.naturalHeight,
      _860: (x0,x1) => { x0.crossOrigin = x1 },
      _862: (x0,x1) => { x0.decoding = x1 },
      _863: x0 => x0.decode(),
      _868: (x0,x1) => { x0.nonce = x1 },
      _873: (x0,x1) => { x0.width = x1 },
      _875: (x0,x1) => { x0.height = x1 },
      _878: (x0,x1) => x0.getContext(x1),
      _940: (x0,x1) => x0.fetch(x1),
      _941: x0 => x0.status,
      _943: x0 => x0.body,
      _944: x0 => x0.arrayBuffer(),
      _947: x0 => x0.read(),
      _948: x0 => x0.value,
      _949: x0 => x0.done,
      _951: x0 => x0.name,
      _952: x0 => x0.x,
      _953: x0 => x0.y,
      _956: x0 => x0.top,
      _957: x0 => x0.right,
      _958: x0 => x0.bottom,
      _959: x0 => x0.left,
      _971: x0 => x0.height,
      _972: x0 => x0.width,
      _973: x0 => x0.scale,
      _974: (x0,x1) => { x0.value = x1 },
      _977: (x0,x1) => { x0.placeholder = x1 },
      _979: (x0,x1) => { x0.name = x1 },
      _980: x0 => x0.selectionDirection,
      _981: x0 => x0.selectionStart,
      _982: x0 => x0.selectionEnd,
      _985: x0 => x0.value,
      _987: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _988: x0 => x0.readText(),
      _989: (x0,x1) => x0.writeText(x1),
      _991: x0 => x0.altKey,
      _992: x0 => x0.code,
      _993: x0 => x0.ctrlKey,
      _994: x0 => x0.key,
      _995: x0 => x0.keyCode,
      _996: x0 => x0.location,
      _997: x0 => x0.metaKey,
      _998: x0 => x0.repeat,
      _999: x0 => x0.shiftKey,
      _1000: x0 => x0.isComposing,
      _1002: x0 => x0.state,
      _1003: (x0,x1) => x0.go(x1),
      _1005: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1006: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1007: x0 => x0.pathname,
      _1008: x0 => x0.search,
      _1009: x0 => x0.hash,
      _1013: x0 => x0.state,
      _1016: (x0,x1) => x0.createObjectURL(x1),
      _1018: x0 => new Blob(x0),
      _1020: x0 => new MutationObserver(x0),
      _1021: (x0,x1,x2) => x0.observe(x1,x2),
      _1022: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1022(f,arguments.length,x0,x1) }),
      _1025: x0 => x0.attributeName,
      _1026: x0 => x0.type,
      _1027: x0 => x0.matches,
      _1028: x0 => x0.matches,
      _1032: x0 => x0.relatedTarget,
      _1034: x0 => x0.clientX,
      _1035: x0 => x0.clientY,
      _1036: x0 => x0.offsetX,
      _1037: x0 => x0.offsetY,
      _1040: x0 => x0.button,
      _1041: x0 => x0.buttons,
      _1042: x0 => x0.ctrlKey,
      _1046: x0 => x0.pointerId,
      _1047: x0 => x0.pointerType,
      _1048: x0 => x0.pressure,
      _1049: x0 => x0.tiltX,
      _1050: x0 => x0.tiltY,
      _1051: x0 => x0.getCoalescedEvents(),
      _1054: x0 => x0.deltaX,
      _1055: x0 => x0.deltaY,
      _1056: x0 => x0.wheelDeltaX,
      _1057: x0 => x0.wheelDeltaY,
      _1058: x0 => x0.deltaMode,
      _1065: x0 => x0.changedTouches,
      _1068: x0 => x0.clientX,
      _1069: x0 => x0.clientY,
      _1072: x0 => x0.data,
      _1075: (x0,x1) => { x0.disabled = x1 },
      _1077: (x0,x1) => { x0.type = x1 },
      _1078: (x0,x1) => { x0.max = x1 },
      _1079: (x0,x1) => { x0.min = x1 },
      _1080: x0 => x0.value,
      _1081: (x0,x1) => { x0.value = x1 },
      _1082: x0 => x0.disabled,
      _1083: (x0,x1) => { x0.disabled = x1 },
      _1085: (x0,x1) => { x0.placeholder = x1 },
      _1087: (x0,x1) => { x0.name = x1 },
      _1089: (x0,x1) => { x0.autocomplete = x1 },
      _1090: x0 => x0.selectionDirection,
      _1092: x0 => x0.selectionStart,
      _1093: x0 => x0.selectionEnd,
      _1096: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1097: (x0,x1) => x0.add(x1),
      _1100: (x0,x1) => { x0.noValidate = x1 },
      _1101: (x0,x1) => { x0.method = x1 },
      _1102: (x0,x1) => { x0.action = x1 },
      _1128: x0 => x0.orientation,
      _1129: x0 => x0.width,
      _1130: x0 => x0.height,
      _1131: (x0,x1) => x0.lock(x1),
      _1150: x0 => new ResizeObserver(x0),
      _1153: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1153(f,arguments.length,x0,x1) }),
      _1161: x0 => x0.length,
      _1162: x0 => x0.iterator,
      _1163: x0 => x0.Segmenter,
      _1164: x0 => x0.v8BreakIterator,
      _1165: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1166: x0 => x0.done,
      _1167: x0 => x0.value,
      _1168: x0 => x0.index,
      _1172: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1173: (x0,x1) => x0.adoptText(x1),
      _1174: x0 => x0.first(),
      _1175: x0 => x0.next(),
      _1176: x0 => x0.current(),
      _1182: x0 => x0.hostElement,
      _1183: x0 => x0.viewConstraints,
      _1186: x0 => x0.maxHeight,
      _1187: x0 => x0.maxWidth,
      _1188: x0 => x0.minHeight,
      _1189: x0 => x0.minWidth,
      _1190: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1190(f,arguments.length,x0) }),
      _1191: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1191(f,arguments.length,x0) }),
      _1192: (x0,x1) => ({addView: x0,removeView: x1}),
      _1193: x0 => x0.loader,
      _1194: () => globalThis._flutter,
      _1195: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1196: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1196(f,arguments.length,x0) }),
      _1197: f => finalizeWrapper(f, function() { return dartInstance.exports._1197(f,arguments.length) }),
      _1198: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1199: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1199(f,arguments.length,x0) }),
      _1200: x0 => ({runApp: x0}),
      _1201: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1201(f,arguments.length,x0,x1) }),
      _1202: x0 => x0.length,
      _1203: () => globalThis.window.ImageDecoder,
      _1204: x0 => x0.tracks,
      _1206: x0 => x0.completed,
      _1208: x0 => x0.image,
      _1214: x0 => x0.displayWidth,
      _1215: x0 => x0.displayHeight,
      _1216: x0 => x0.duration,
      _1219: x0 => x0.ready,
      _1220: x0 => x0.selectedTrack,
      _1221: x0 => x0.repetitionCount,
      _1222: x0 => x0.frameCount,
      _1265: x0 => x0.createRange(),
      _1266: (x0,x1) => x0.selectNode(x1),
      _1267: x0 => x0.getSelection(),
      _1268: x0 => x0.removeAllRanges(),
      _1269: (x0,x1) => x0.addRange(x1),
      _1270: (x0,x1) => x0.createElement(x1),
      _1271: (x0,x1) => x0.append(x1),
      _1272: (x0,x1,x2) => x0.insertRule(x1,x2),
      _1273: (x0,x1) => x0.add(x1),
      _1274: x0 => x0.preventDefault(),
      _1275: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1275(f,arguments.length,x0) }),
      _1276: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1278: x0 => x0.remove(),
      _1280: x0 => globalThis.URL.createObjectURL(x0),
      _1283: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1283(f,arguments.length,x0) }),
      _1284: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1284(f,arguments.length,x0) }),
      _1285: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1285(f,arguments.length,x0) }),
      _1286: (x0,x1) => x0.querySelector(x1),
      _1287: (x0,x1) => x0.createElement(x1),
      _1288: (x0,x1) => x0.append(x1),
      _1289: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1290: (x0,x1) => x0.replaceChildren(x1),
      _1291: x0 => x0.click(),
      _1299: (x0,x1) => x0.getItem(x1),
      _1301: (x0,x1,x2) => x0.setItem(x1,x2),
      _1302: (x0,x1) => x0.getAttribute(x1),
      _1303: Date.now,
      _1305: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1306: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1307: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1308: () => typeof dartUseDateNowForTicks !== "undefined",
      _1309: () => 1000 * performance.now(),
      _1310: () => Date.now(),
      _1311: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1312: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1313: () => new WeakMap(),
      _1314: (map, o) => map.get(o),
      _1315: (map, o, v) => map.set(o, v),
      _1316: x0 => new WeakRef(x0),
      _1317: x0 => x0.deref(),
      _1324: () => globalThis.WeakRef,
      _1327: x0 => x0.call(),
      _1328: s => JSON.stringify(s),
      _1329: s => printToConsole(s),
      _1330: (o, p, r) => o.replaceAll(p, () => r),
      _1331: (o, p, r) => o.replace(p, () => r),
      _1332: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1333: s => s.toUpperCase(),
      _1334: s => s.trim(),
      _1335: s => s.trimLeft(),
      _1336: s => s.trimRight(),
      _1337: (string, times) => string.repeat(times),
      _1338: Function.prototype.call.bind(String.prototype.indexOf),
      _1339: (s, p, i) => s.lastIndexOf(p, i),
      _1340: (string, token) => string.split(token),
      _1341: Object.is,
      _1342: o => o instanceof Array,
      _1343: (a, i) => a.push(i),
      _1345: (a, i, v) => a.splice(i, 0, v),
      _1347: a => a.pop(),
      _1348: (a, i) => a.splice(i, 1),
      _1349: (a, s) => a.join(s),
      _1350: (a, s, e) => a.slice(s, e),
      _1352: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1353: a => a.length,
      _1355: (a, i) => a[i],
      _1356: (a, i, v) => a[i] = v,
      _1358: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _1359: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1361: o => o instanceof Uint8Array,
      _1362: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1363: o => o instanceof Int8Array,
      _1364: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1365: o => o instanceof Uint8ClampedArray,
      _1366: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1367: o => o instanceof Uint16Array,
      _1368: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1369: o => o instanceof Int16Array,
      _1370: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1371: o => o instanceof Uint32Array,
      _1372: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1373: o => o instanceof Int32Array,
      _1374: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1376: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1377: o => o instanceof Float32Array,
      _1378: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1379: o => o instanceof Float64Array,
      _1380: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1381: (t, s) => t.set(s),
      _1382: l => new DataView(new ArrayBuffer(l)),
      _1383: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1384: o => o.byteLength,
      _1385: o => o.buffer,
      _1386: o => o.byteOffset,
      _1387: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1388: (b, o) => new DataView(b, o),
      _1389: (b, o, l) => new DataView(b, o, l),
      _1390: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1391: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1392: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1393: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1394: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1395: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1396: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1397: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1398: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1399: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1400: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1401: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1404: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1405: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1406: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1407: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1408: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1409: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1422: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1423: (handle) => clearTimeout(handle),
      _1424: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1425: (handle) => clearInterval(handle),
      _1426: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1427: () => Date.now(),
      _1432: o => Object.keys(o),
      _1435: (x0,x1) => x0.update(x1),
      _1436: x0 => x0.delete(),
      _1437: x0 => x0.continue(),
      _1440: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1440(f,arguments.length,x0) }),
      _1441: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1441(f,arguments.length,x0) }),
      _1452: (x0,x1) => x0.getKey(x1),
      _1455: x0 => x0.openKeyCursor(),
      _1458: x0 => x0.openCursor(),
      _1461: (x0,x1) => ({unique: x0,multiEntry: x1}),
      _1462: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _1464: (x0,x1) => x0.add(x1),
      _1466: (x0,x1) => x0.get(x1),
      _1468: (x0,x1) => x0.put(x1),
      _1469: (x0,x1,x2) => x0.put(x1,x2),
      _1470: (x0,x1) => x0.delete(x1),
      _1471: (x0,x1) => x0.index(x1),
      _1472: x0 => x0.openCursor(),
      _1473: (x0,x1) => x0.openCursor(x1),
      _1479: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1479(f,arguments.length,x0) }),
      _1480: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1480(f,arguments.length,x0) }),
      _1481: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1481(f,arguments.length,x0) }),
      _1482: (x0,x1) => x0.objectStore(x1),
      _1484: (x0,x1) => ({keyPath: x0,autoIncrement: x1}),
      _1485: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _1486: (x0,x1,x2) => x0.transaction(x1,x2),
      _1487: x0 => x0.close(),
      _1490: (x0,x1,x2) => x0.open(x1,x2),
      _1491: (x0,x1) => x0.open(x1),
      _1493: (x0,x1) => x0.deleteDatabase(x1),
      _1496: (x0,x1) => x0.postMessage(x1),
      _1497: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1497(f,arguments.length,x0) }),
      _1498: x0 => new BroadcastChannel(x0),
      _1500: (x0,x1) => globalThis.IDBKeyRange.lowerBound(x0,x1),
      _1501: (x0,x1) => globalThis.IDBKeyRange.upperBound(x0,x1),
      _1508: (x0,x1) => x0.item(x1),
      _1509: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1509(f,arguments.length,x0) }),
      _1510: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1510(f,arguments.length,x0) }),
      _1511: () => globalThis.indexedDB,
      _1513: x0 => x0.arrayBuffer(),
      _1561: (x0,x1) => x0.sqlite3_user_data(x1),
      _1587: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      _1589: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      _1599: x0 => ({initial: x0}),
      _1600: x0 => new WebAssembly.Memory(x0),
      _1601: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1601(f,arguments.length,x0) }),
      _1602: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1602(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1603: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1603(f,arguments.length,x0,x1,x2) }),
      _1604: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1604(f,arguments.length,x0,x1,x2,x3) }),
      _1605: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1605(f,arguments.length,x0,x1,x2,x3) }),
      _1606: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1606(f,arguments.length,x0,x1,x2) }),
      _1607: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1607(f,arguments.length,x0,x1) }),
      _1608: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1608(f,arguments.length,x0,x1) }),
      _1609: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1609(f,arguments.length,x0) }),
      _1610: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1610(f,arguments.length,x0) }),
      _1611: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1611(f,arguments.length,x0,x1,x2,x3) }),
      _1612: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1612(f,arguments.length,x0,x1,x2,x3) }),
      _1613: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1613(f,arguments.length,x0,x1) }),
      _1614: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1614(f,arguments.length,x0,x1) }),
      _1615: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1615(f,arguments.length,x0,x1) }),
      _1616: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1616(f,arguments.length,x0,x1) }),
      _1617: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1617(f,arguments.length,x0,x1) }),
      _1618: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1618(f,arguments.length,x0,x1) }),
      _1619: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1619(f,arguments.length,x0,x1,x2) }),
      _1620: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1620(f,arguments.length,x0,x1,x2) }),
      _1621: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1621(f,arguments.length,x0,x1,x2) }),
      _1622: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1622(f,arguments.length,x0) }),
      _1623: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1623(f,arguments.length,x0) }),
      _1624: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1624(f,arguments.length,x0) }),
      _1625: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1625(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1626: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1626(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1627: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1627(f,arguments.length,x0) }),
      _1628: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1628(f,arguments.length,x0) }),
      _1629: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1629(f,arguments.length,x0,x1) }),
      _1630: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1630(f,arguments.length,x0,x1) }),
      _1631: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1631(f,arguments.length,x0,x1,x2) }),
      _1638: x0 => new URL(x0),
      _1639: (x0,x1) => new URL(x0,x1),
      _1640: (x0,x1) => globalThis.fetch(x0,x1),
      _1641: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1643: (x0,x1) => x0.error(x1),
      _1644: () => new MessageChannel(),
      _1645: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1645(f,arguments.length,x0) }),
      _1646: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1647: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1647(f,arguments.length,x0) }),
      _1648: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1648(f,arguments.length,x0) }),
      _1649: (x0,x1) => new SharedWorker(x0,x1),
      _1650: x0 => new Worker(x0),
      _1663: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      _1664: x0 => ({autoIncrement: x0}),
      _1665: x0 => ({unique: x0}),
      _1666: (x0,x1) => x0.createObjectStore(x1),
      _1667: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1667(f,arguments.length,x0) }),
      _1668: (x0,x1) => ({name: x0,length: x1}),
      _1669: x0 => globalThis.IDBKeyRange.only(x0),
      _1670: x0 => x0.name,
      _1671: x0 => x0.length,
      _1676: x0 => globalThis.BigInt(x0),
      _1677: x0 => globalThis.Number(x0),
      _1694: () => new AbortController(),
      _1695: x0 => x0.abort(),
      _1696: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1697: (x0,x1) => globalThis.fetch(x0,x1),
      _1698: (x0,x1) => x0.get(x1),
      _1699: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1699(f,arguments.length,x0,x1,x2) }),
      _1700: (x0,x1) => x0.forEach(x1),
      _1701: x0 => x0.getReader(),
      _1702: x0 => x0.read(),
      _1703: x0 => x0.cancel(),
      _1707: () => new XMLHttpRequest(),
      _1708: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1709: x0 => x0.send(),
      _1711: () => new FileReader(),
      _1712: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1719: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1719(f,arguments.length,x0) }),
      _1720: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1720(f,arguments.length,x0) }),
      _1721: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1722: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1728: x0 => x0.exports,
      _1729: (x0,x1) => globalThis.WebAssembly.instantiateStreaming(x0,x1),
      _1730: x0 => x0.instance,
      _1732: x0 => x0.buffer,
      _1736: (x0,x1) => x0.key(x1),
      _1737: (x0,x1) => x0.item(x1),
      _1747: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1748: (x0,x1) => x0.exec(x1),
      _1749: (x0,x1) => x0.test(x1),
      _1750: x0 => x0.pop(),
      _1752: o => o === undefined,
      _1754: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1756: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1757: o => o instanceof RegExp,
      _1758: (l, r) => l === r,
      _1759: o => o,
      _1760: o => o,
      _1761: o => o,
      _1762: b => !!b,
      _1763: o => o.length,
      _1765: (o, i) => o[i],
      _1766: f => f.dartFunction,
      _1767: () => ({}),
      _1768: () => [],
      _1770: () => globalThis,
      _1771: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1773: (o, p) => o[p],
      _1774: (o, p, v) => o[p] = v,
      _1775: (o, m, a) => o[m].apply(o, a),
      _1777: o => String(o),
      _1778: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1779: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        return 18;
      },
      _1780: o => [o],
      _1781: (o0, o1) => [o0, o1],
      _1782: (o0, o1, o2) => [o0, o1, o2],
      _1783: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1784: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1785: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1788: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1789: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1790: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1791: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1792: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1793: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1794: x0 => new ArrayBuffer(x0),
      _1795: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1797: x0 => x0.index,
      _1799: x0 => x0.flags,
      _1800: x0 => x0.multiline,
      _1801: x0 => x0.ignoreCase,
      _1802: x0 => x0.unicode,
      _1803: x0 => x0.dotAll,
      _1804: (x0,x1) => { x0.lastIndex = x1 },
      _1805: (o, p) => p in o,
      _1806: (o, p) => o[p],
      _1807: (o, p, v) => o[p] = v,
      _1809: x0 => globalThis.Object.keys(x0),
      _1810: x0 => new Date(x0),
      _1812: x0 => x0.getTime(),
      _1813: x0 => x0.length,
      _1814: x0 => x0.message,
      _1815: x0 => x0.name,
      _1828: x0 => globalThis.Object.keys(x0),
      _1829: x0 => x0.length,
      _1830: x0 => x0.random(),
      _1831: (x0,x1) => x0.getRandomValues(x1),
      _1832: () => globalThis.crypto,
      _1833: () => globalThis.Math,
      _1834: Function.prototype.call.bind(Number.prototype.toString),
      _1835: Function.prototype.call.bind(BigInt.prototype.toString),
      _1836: Function.prototype.call.bind(Number.prototype.toString),
      _1837: (d, digits) => d.toFixed(digits),
      _1841: () => globalThis.window,
      _1842: x0 => x0.crypto,
      _1843: x0 => x0.subtle,
      _1849: (x0,x1,x2) => x0.digest(x1,x2),
      _1850: (x0,x1,x2,x3) => x0.deriveBits(x1,x2,x3),
      _1853: (x0,x1,x2,x3,x4,x5) => x0.importKey(x1,x2,x3,x4,x5),
      _1857: x0 => x0.type,
      _1862: x0 => x0.name,
      _1863: x0 => x0.message,
      _1885: () => globalThis.document,
      _1886: () => globalThis.window,
      _1891: (x0,x1) => { x0.height = x1 },
      _1893: (x0,x1) => { x0.width = x1 },
      _1896: x0 => x0.head,
      _1897: x0 => x0.classList,
      _1901: (x0,x1) => { x0.innerText = x1 },
      _1902: x0 => x0.style,
      _1904: x0 => x0.sheet,
      _1915: x0 => x0.offsetX,
      _1916: x0 => x0.offsetY,
      _1917: x0 => x0.button,
      _1976: (x0,x1) => { x0.responseType = x1 },
      _1977: x0 => x0.response,
      _2013: x0 => x0.length,
      _2065: (x0,x1) => { x0.oncancel = x1 },
      _2071: (x0,x1) => { x0.onchange = x1 },
      _2111: (x0,x1) => { x0.onerror = x1 },
      _2267: (x0,x1) => { x0.href = x1 },
      _2981: (x0,x1) => { x0.accept = x1 },
      _2995: x0 => x0.files,
      _3021: (x0,x1) => { x0.multiple = x1 },
      _3039: (x0,x1) => { x0.type = x1 },
      _3289: (x0,x1) => { x0.src = x1 },
      _3295: (x0,x1) => { x0.async = x1 },
      _3757: () => globalThis.window,
      _3820: x0 => x0.navigator,
      _4077: x0 => x0.indexedDB,
      _4084: x0 => x0.localStorage,
      _4210: x0 => x0.vendor,
      _4260: x0 => x0.data,
      _4290: x0 => x0.port1,
      _4291: x0 => x0.port2,
      _4295: (x0,x1) => { x0.onmessage = x1 },
      _4306: (x0,x1) => { x0.onmessage = x1 },
      _4368: (x0,x1) => { x0.onerror = x1 },
      _4376: x0 => x0.port,
      _4378: (x0,x1) => { x0.onerror = x1 },
      _4411: x0 => x0.length,
      _6315: x0 => x0.type,
      _6316: x0 => x0.target,
      _6356: x0 => x0.signal,
      _6428: () => globalThis.document,
      _6510: x0 => x0.body,
      _6843: (x0,x1) => { x0.id = x1 },
      _6866: x0 => x0.innerHTML,
      _6867: (x0,x1) => { x0.innerHTML = x1 },
      _8189: x0 => x0.value,
      _8191: x0 => x0.done,
      _8355: x0 => x0.size,
      _8356: x0 => x0.type,
      _8363: x0 => x0.name,
      _8364: x0 => x0.lastModified,
      _8369: x0 => x0.length,
      _8375: x0 => x0.result,
      _8871: x0 => x0.url,
      _8873: x0 => x0.status,
      _8875: x0 => x0.statusText,
      _8876: x0 => x0.headers,
      _8877: x0 => x0.body,
      _10333: x0 => x0.result,
      _10334: x0 => x0.error,
      _10339: (x0,x1) => { x0.onsuccess = x1 },
      _10341: (x0,x1) => { x0.onerror = x1 },
      _10345: (x0,x1) => { x0.onupgradeneeded = x1 },
      _10347: x0 => x0.oldVersion,
      _10360: x0 => x0.name,
      _10362: x0 => x0.objectStoreNames,
      _10379: x0 => x0.name,
      _10381: x0 => x0.keyPath,
      _10384: x0 => x0.autoIncrement,
      _10389: x0 => x0.name,
      _10392: x0 => x0.keyPath,
      _10393: x0 => x0.multiEntry,
      _10394: x0 => x0.unique,
      _10403: x0 => x0.key,
      _10404: x0 => x0.primaryKey,
      _10406: x0 => x0.value,
      _10412: x0 => x0.error,
      _10414: (x0,x1) => { x0.onabort = x1 },
      _10416: (x0,x1) => { x0.oncomplete = x1 },
      _10418: (x0,x1) => { x0.onerror = x1 },
      _12466: x0 => x0.name,
      _12467: x0 => x0.message,
      _13183: () => globalThis.console,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
