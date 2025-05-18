# React Native MMKV Storage

<div align="center">
  <a align="center" href="https://github.com/ammarahm-ed/react-native-mmkv-storage">
    <img src="https://github.com/ammarahm-ed/react-native-mmkv-storage/blob/master/static/cover.png?raw=true" alt="react-native-mmkv-storage" />
  </a>
<p align="center" ><a href="https://twitter.com/ammarahmed_o">Twitter</a> &bull; <a  href="https://github.com/ammarahm-ed/react-native-mmkv-storage">Github</a> &bull; <a href="https://github.com/ammarahm-ed/react-native-mmkv-storage/blob/master/example/mmkv-storage-structure.svg">MMKV Internals</a></p>
<p align="center">
  <a href="https://www.npmjs.com/package/react-native-mmkv-storage">
    <img src="https://img.shields.io/npm/v/react-native-mmkv-storage?color=brightgreen">
  </a>
  <a href="https://www.npmjs.com/package/react-native-mmkv-storage">
    <img src="https://img.shields.io/npm/dt/react-native-mmkv-storage">
  </a>
</p>
</div>

## Version 0.11.11 Update
This version fixes additional iOS issues with React Native 0.77+:
- Fixed nested JSI string conversion in object and array storage methods
- Resolved the "no member named 'asString' in 'facebook::jsi::String'" error
- Improved handling of JSON stringification results on iOS

## Version 0.11.10 Update
This version fixes iOS compatibility with React Native 0.77+:
- Updated iOS implementation to use `asString()` instead of `getString()`
- Fixed JSON object and array handling on iOS
- Added `getMultiObjectMMKV` native function for iOS
- Ensures consistent API between iOS and Android for native JSON parsing

## Version 0.11.9 Update
This version adds native JSON parsing for multiple items retrieval:
- Added `getMultiObjectMMKV` native function for parsing JSON in C++ for multiple keys at once
- Added `getMultipleItemsNative` and `getMultipleItemsNativeAsync` methods that use native parsing
- Improves performance when retrieving large collections of objects from storage
- Handles JSON parsing errors gracefully by returning the raw string when parsing fails

## Version 0.11.8 Update
This version includes fixes for React Native 0.77+ compatibility:
- Fixed JSON access in native code to properly handle JSON as an object not a function
- Updated JSON.stringify and JSON.parse calls to work with newer JSI APIs
- Corrected the "getPropertyAsFunction" error when accessing JSON methods

## Version 0.11.7 Update
This version includes fixes for React Native 0.77+ compatibility:
- Fixed JSI API compatibility issues by updating String handling methods
- Updated the code to work with newer JSI APIs that removed the getString() method
- Object and array serialization/deserialization now works correctly with the new JSI API

## What it is

This library aims to provide a fast & reliable solution for you data storage needs in react-native apps. It uses [MMKV](https://github.com/Tencent/MMKV) by Tencent under the hood on Android and iOS both that is used by their WeChat app(more than 1 Billion users). Unlike other storage solutions for React Native, this library lets you store any kind of data type, in any number of database instances, with or without encryption in a very fast and efficient way. Read about it on this blog post I wrote on [dev.to](https://dev.to/ammarahmed/best-data-storage-option-for-react-native-apps-42k)

> Learn how to build your own module with JSI on my [blog](https://blog.notesnook.com/getting-started-react-native-jsi/)

## 0.9.0 Breaking change

Works only with react native 0.71.0 and above. If you are on older version of react native, keep using 0.8.x.

## Features

### **Written in C++ using JSI**

Starting from `v0.5.0` the library has been rewritten in C++ on Android and iOS both. It employs React Native JSI making it the fastest storage option for React Native.

### **Simple and lightweight**

(~ 50K Android/30K iOS) and even smaller when packaged.

### **Fast and Efficient (0.0002s Read/Write Speed)**

MMKV uses mmap to keep memory synced with file, and protobuf to encode/decode values to achieve best performance.
You can see the benchmarks here: [Android](https://github.com/Tencent/MMKV/wiki/android_benchmark) & [iOS](https://github.com/Tencent/MMKV/wiki/iOS_benchmark)

### **Reactive using `useMMKVStorage` & `useIndex` Hooks**

Hooks let's the storage update your app when a change takes place in storage.

#### `useMMKVStorage` hook

Starting from `v0.5.5`, thanks to the power of JSI, we now have our very own `useMMKVStorage` Hook. Think of it like a persisted state that will always write every change in storage and update your app UI instantly. It doesn't matter if you reload the app or restart it.

```js
import { MMKVLoader, useMMKVStorage } from 'react-native-mmkv-storage';

const storage = new MMKVLoader().initialize();
const App = () => {
  const [user, setUser] = useMMKVStorage('user', storage, 'robert');
  const [age, setAge] = useMMKVStorage('age', storage, 24);

  return (
    <View style={styles.header}>
      <Text style={styles.headerText}>
        I am {user} and I am {age} years old.
      </Text>
    </View>
  );
};
```

Learn more about `useMMKVStorage` hook it in the [docs](https://rnmmkv.vercel.app/#/usemmkvstorage).

#### `useIndex`