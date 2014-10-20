'use strict';
function trim(string) {
  return string.replace(/^\s*(.*?)\s*$/, '$1');
}

function convertHexColorToDec(value) {
    var a, b, c;
    value = value.substr(1);
    if (value.length === 3) {
        a = value.substr(0, 1);
        b = value.substr(1, 1);
        c = value.substr(2, 1);
        value = a + a + b + b + c + c;
    }
    return {
        r: parseInt(value.substr(0, 2), 16),
        g: parseInt(value.substr(2, 2), 16),
        b: parseInt(value.substr(4, 2), 16)
    };
}

function parser(cssString) {
    var propertys,
        returnObj = {},
        i;

    cssString = cssString || '';

    if (typeof cssString === 'string') {
        propertys = cssString.split(';');

        for (i = propertys.length - 1; i >= 0; i--) {
            var split = propertys[i].split(':');
            if (split[1]) {
                returnObj[trim(split[0])] = trim(split[1]);
            }
        }
    } else {
        returnObj = cssString;
    }

    return returnObj;
}

function getType(value) {
    var retVal = false;
    if (typeof value === 'string') {
        if (/\#[0-9a-f]{3}/gi.test(value) || /\#[0-9a-fA-F]{6}/gi.test(value)) {
            retVal = 'color';
        } else if (/(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms|^\d+)$/gi.test(value)) {
            retVal = 'number';
        } else if (/^[^\s\(]+\(.*?\)$/.test(value)) {
            retVal = 'object';
        } else {
            retVal = 'string';
        }
    }
    return retVal;
}

function getTypeExt(value, type) {
    if (type === 'number' && /.*?(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms)$/gi.test(value)) {
        return value.replace(/.*?(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms)$/gi, '$1');
    }
    return '';
}

function getValue(value, type) {
    var parserOutput;
    if (type === 'color') {
        value = convertHexColorToDec(value);
    } else if (type === 'number') {
        value = parseFloat(value.replace(/(.*?)(?:px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms)$/gi, '$1'));
    } else if (type === 'object') {
        parserOutput = parser(value.replace(/^([^\(]+)\(([^\)]+)\)$/, '$1:$2').replace(',', ' '));
        console.log('parser("' + value + '") -> ', parserOutput);
        value = valuesParser(parserOutput);
    }

    return value;
}

function valuesParser(cssObj) {
  cssObj = cssObj || {};

  for (var property in cssObj) {
    // replace spcaes after a comma to preven obj type values to be splitted into 2 parts
    var valueArray = cssObj[property].replace(/, +/,',').split(' '),
        finalValueArray = [];

    console.log('valueArray:', valueArray);
    for (var i = valueArray.length - 1; i >= 0; i--) {
      var valueType = getType(valueArray[i]);
      finalValueArray.push({
        val: getValue(valueArray[i], valueType),
        type: valueType,
        ext: getTypeExt(valueArray[i], valueType)
      });
    };

    cssObj[property] = finalValueArray;
  }

  return cssObj;
}

