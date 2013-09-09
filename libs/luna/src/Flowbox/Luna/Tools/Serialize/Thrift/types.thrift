///////////////////////////////////////////////////////////////////////////
// Copyright (C) Flowbox, Inc / All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
// Flowbox Team <contact@flowbox.io>, 2013
///////////////////////////////////////////////////////////////////////////

namespace cpp flowbox.batch.types
namespace hs  flowbox.batch.types


enum TypeType {
    Undefined = 0,
    Module    = 1,
    Function  = 2,
    Class     = 3,
    Interface = 4,
    Named     = 5,
    TypeName  = 6,
    Tuple     = 7;
}


struct TypeProto {
    1: required TypeType     cls
    2: optional string       name
    3: optional list<i32>    items   = []
    4: optional list<string> params  = []
    5: optional list<i32>    fields  = []
    6: optional i32          inputs
    7: optional i32          outputs
    8: optional i32          type
}


struct Type { 
    1: optional list<TypeProto> types
}