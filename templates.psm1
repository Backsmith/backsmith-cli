#region Get-ApiResponseTemplate
function Get-ApiResponseTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { HttpStatus } from "./httpStatus.enum.js";
import { ServiceStatus } from "../services/serviceStatus.enum.js";
"@
    } else {
        @"
const { HttpStatus } = require("./httpStatus.enum");
const { ServiceStatus } = require("../services/serviceStatus.enum");
"@
    }
    $body = @"
const apiResponse = (httpMethod, httpResponse, serviceResponse) => {
    switch (serviceResponse.status) {
        case ServiceStatus.OK:
            switch (httpMethod) {
                case "GET": return httpResponse.json({ data: serviceResponse.data });
                case "POST": return httpResponse.status(HttpStatus.CREATED).end();
                case "PATCH":
                case "PUT":
                case "DELETE": return httpResponse.status(HttpStatus.NO_CONTENT).end();
                // no default on purpose: fail fast if a new HTTP verb is used in a route and not defined here.
            }
        case ServiceStatus.NOT_FOUND:
            return httpResponse.status(HttpStatus.NOT_FOUND).json({ error: serviceResponse.error });
        case ServiceStatus.BAD_REQUEST:
            return httpResponse.status(HttpStatus.BAD_REQUEST).json({ errors: serviceResponse.errors });
        default:
            return httpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR).json({ error: serviceResponse.error });
    }
};
"@
    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { apiResponse };"
    } else {
        "module.exports = { apiResponse };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-AppTemplate
function Get-AppTemplate($moduleSystem, $structureType) {
    $mainRouterImportPath = if ($structureType -eq "layer") {
        "./routes/index"
    } else {
        "./shared/routes/index"
    }
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import dotenv from "dotenv";
dotenv.config();

const PORT = process.env.PORT ?? 3000;

import express from "express";
import cors from "cors";

import { logger } from "./middleware/logger.js";
import { notFoundHandler, errorHandler } from "./middleware/errors.handler.js";
import { mainRouter } from "$mainRouterImportPath.js";
"@
    } else {
        @"
require("dotenv").config();
const PORT = process.env.PORT ?? 3000;

const express = require("express");
const cors = require("cors");

const { logger } = require("./middleware/logger");
const { notFoundHandler, errorHandler } = require("./middleware/errors.handler");
const { mainRouter } = require("$mainRouterImportPath");
"@
    }

    $sharedBody = @"
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(logger);

app.use("/api", mainRouter);

app.use(notFoundHandler);
app.use(errorHandler);

app.listen(PORT, () => console.log(``App running on port `${PORT}``));
"@

    return "$importBlock`n`n$sharedBody"
}
#endregion

#region Get-ControllerTemplate
function Get-ControllerTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { apiResponse } from "./apiResponse.js";
"@
    } else {
        @"
const { apiResponse } = require("./apiResponse");
"@
    }
    $body = @"
class Controller {

    constructor(service) {
        if (new.target === Controller) {
            throw new Error("Controller is a base class and must be extended, not instantiated directly.");
        }
        this.service = service;
    }

    async get(req, res) {
        const serviceResponse = await this.service.get(req.query);
        return apiResponse(req.method, res, serviceResponse);
    }

    async getById(req, res) {
        const serviceResponse = await this.service.getById(req.params.id);
        return apiResponse(req.method, res, serviceResponse);
    }

    async create(req, res) {
        const serviceResponse = await this.service.create(req.body);
        return apiResponse(req.method, res, serviceResponse);
    }

    async update(req, res) {
        const serviceResponse = await this.service.update(req.params.id, req.body);
        return apiResponse(req.method, res, serviceResponse);
    }

    async replace(req, res) {
        const serviceResponse = await this.service.replace(req.params.id, req.body);
        return apiResponse(req.method, res, serviceResponse);
    }

    async remove(req, res) {
        const serviceResponse = await this.service.remove(req.params.id);
        return apiResponse(req.method, res, serviceResponse);
    }

}
"@
    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { Controller };"
    } else {
        "module.exports = { Controller };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-CriteriaBuilderNoSequelizeTemplate
function Get-CriteriaBuilderNoSequelizeTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { CriteriaType } from "./criteriaType.enum.js";
"@
    } else {
        @"
const { CriteriaType } = require("./criteriaType.enum");
"@
    }
    $body = @"
const buildFromWhereClauses = (whereClauses) => {
    const where = {};
    whereClauses.forEach(({ config, value }) => {
        switch (config.type) {
            case CriteriaType.PERFECT_MATCH:
                addPerfectMatchCriteria(where, config.field, value);
                break;
            case CriteriaType.PARTIAL_MATCH:
                addPartialMatchCriteria(where, config.field, value);
                break;
            case CriteriaType.BOUND_MIN:
                addNumericBoundCriteria(where, config.field, CriteriaType.BOUND_MIN, value);
                break;
            case CriteriaType.BOUND_MAX:
                addNumericBoundCriteria(where, config.field, CriteriaType.BOUND_MAX, value);
                break;
            default:
                console.warn(``Unknown criteria type : `${config.type}``);
        }
    });
    return where;
};

const addPerfectMatchCriteria = (where, fieldName, value) => {
    // TODO: replace by your own implementation
    where[fieldName] = item => item[fieldName] === value;
};

const addPartialMatchCriteria = (where, fieldName, value) => {
    // TODO: replace by your own implementation
    where[fieldName] = item =>
        typeof item[fieldName] === "string" && item[fieldName].includes(value);
};

const addNumericBoundCriteria = (where, fieldName, minOrMax, value) => {
    // TODO: replace by your own implementation
    const existing = where[fieldName] || (() => true);
    where[fieldName] = item => {
        const val = item[fieldName];
        const minOk = minOrMax === CriteriaType.BOUND_MIN ? val >= value : true;
        const maxOk = minOrMax === CriteriaType.BOUND_MAX ? val < value : true;
        return existing(item) && minOk && maxOk;
    };
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export const criteriaBuilder = { buildFromWhereClauses };"
    } else {
        "module.exports = { criteriaBuilder: { buildFromWhereClauses } };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-CriteriaTypeEnumTemplate
function Get-CriteriaTypeEnumTemplate($moduleSystem) {
    $body = @"
// This enum represents the type of filters you want to be able to apply when querying the database.
// You can easily add your own types by providing criteriaBuilder.js with an implementation for them.
const CriteriaType = {
    PERFECT_MATCH: "PERFECT_MATCH",
    PARTIAL_MATCH: "PARTIAL_MATCH",
    BOUND_MIN: "BOUND_MIN",
    BOUND_MAX: "BOUND_MAX"
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { CriteriaType };"
    } else {
        "module.exports = { CriteriaType };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-DataTemplate
function Get-DataTemplate($moduleSystem) {
    $exportLine = if ($moduleSystem -eq "esm") {
        "export default ["
    } else {
        "module.exports = ["
    }

    return @"
$exportLine
  {
    id: 1,
    field1: "Alpha",               // STRING_LENGTH ≤ 10
    field2: "OptionalText",        // STRING_LENGTH ≤ 15
    field3: 42,                    // POSITIVE_INTEGER
    field4: 123.45                 // NUMERIC_BOUNDS: 0 < x < 1000, max 2 decimals
  },
  {
    id: 2,
    field1: "Beta",
    field2: "AnotherText",
    field3: 999,
    field4: 999.99
  },
  {
    id: 3,
    field1: "Gamma",
    field2: "Short",
    field3: 1,
    field4: 0.01
  }
];
"@
}
#endregion

#region Get-ErrorHandlerTemplate
function Get-ErrorHandlerTemplate($moduleSystem, $structureType) {
    $httpStatusImportPath = if ($structureType -eq "layer") {
        "../controllers/httpStatus.enum"
    } else {
        "../shared/controllers/httpStatus.enum"
    }
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { HttpStatus } from "$httpStatusImportPath.js";
"@
    } else {
        @"
const { HttpStatus } = require("$httpStatusImportPath");
"@
    }

    $body = @"
const notFoundHandler = (req, res, next) => {
    res.status(HttpStatus.NOT_FOUND).json({ error: ``Path `${req.originalUrl}` not found`` });
};

const errorHandler = (err, req, res, next) => {
    console.log(err.stack);
    res.status(err.status || HttpStatus.INTERNAL_SERVER_ERROR).json({ error: err.message || "Unexpected error" });
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { notFoundHandler, errorHandler };"
    } else {
        "module.exports = { notFoundHandler, errorHandler };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureControllerTemplate
function Get-FeatureControllerTemplate($moduleSystem, $structureType, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $controllerName = "${capitalizedFeature}Controller"
    $serviceName = "${capitalizedFeature}Service"

    $controllerImportPath = if ($structureType -eq "layer") {
        "./controller"
    } else {
        "../../shared/controllers/controller"
    }

    $serviceImportPath = if ($structureType -eq "layer") {
        "../services/$feature.service"
    } else {
        "./$feature.service"
    }

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { Controller } from "$controllerImportPath.js";
import { $serviceName } from "$serviceImportPath.js";
"@
    } else {
        @"
const { Controller } = require("$controllerImportPath");
const { $serviceName } = require("$serviceImportPath");
"@
    }

    $body = @"
class $controllerName extends Controller {

    constructor() {
        super(new $serviceName());

        this.get = this.get.bind(this);
        this.getById = this.getById.bind(this);
        this.create = this.create.bind(this);
        this.update = this.update.bind(this);
        this.replace = this.replace.bind(this);
        this.remove = this.remove.bind(this);
    }

}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $controllerName };"
    } else {
        "module.exports = { $controllerName };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureCriteriaConfigTemplate
function Get-FeatureCriteriaConfigTemplate($moduleSystem, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $configName = "${capitalizedFeature}CriteriaConfig"
    $enumName = "${capitalizedFeature}Criteria"

    $criteriaTypeImportPath = if ($structureType -eq "layer") {
        "./criteriaType.enum"
    } else {
        "../../../shared/repositories/criteria/criteriaType.enum"
    }

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { CriteriaType } from "$criteriaTypeImportPath.js";
import { $enumName } from "./${feature}Criteria.enum.js";
"@
    } else {
        @"
const { CriteriaType } = require("$criteriaTypeImportPath");
const { $enumName } = require("./${feature}Criteria.enum");
"@
    }

    $body = @"
// TODO: Replace with your own fields and configuration. The config keys must match the name of the query params.
const $configName = {
    field1: { type: CriteriaType.PERFECT_MATCH, field: $enumName.FIELD1 },

    field2: { type: CriteriaType.PARTIAL_MATCH, field: $enumName.FIELD2 },

    minField3: { type: CriteriaType.BOUND_MIN, field: $enumName.FIELD3 },
    maxField3: { type: CriteriaType.BOUND_MAX, field: $enumName.FIELD3 }
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $configName };"
    } else {
        "module.exports = { $configName };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureCriteriaEnumTemplate
function Get-FeatureCriteriaEnumTemplate($moduleSystem, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $enumName = "${capitalizedFeature}Criteria"

    $body = @"
// TODO: FIELDS must be replaced by the fields you want to be able to filter on when querying the database.
// The value of each enum must be the exact name of the field in your model.
const $enumName = {
    FIELD1: "field1",
    FIELD2: "field2",
    FIELD3: "field3",
    FIELD4: "field4"
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $enumName };"
    } else {
        "module.exports = { $enumName };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureFieldEnumTemplate
function Get-FeatureFieldEnumTemplate($moduleSystem, $structureType, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $enumName = "${capitalizedFeature}Field"

    $validationPath = if ($structureType -eq "layer") {
        "."
    } else {
        "../../../shared/validation"
    }

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { ValidationType } from "$validationPath/validationType.enum.js";
import { ErrorMessage } from "$validationPath/validationErrorMessage.enum.js";
import { ErrorCode } from "$validationPath/validationErrorCode.enum.js";
"@
    } else {
        @"
const { ValidationType } = require("$validationPath/validationType.enum");
const { ErrorMessage } = require("$validationPath/validationErrorMessage.enum");
const { ErrorCode } = require("$validationPath/validationErrorCode.enum");
"@
    }

    $enumContent = @"
// TODO: Replace with your own fields and configuration.
// Enum keys must match your model field names, converted to CONSTANT_CASE.
// Example: myCamelCaseField => MY_CAMEL_CASE_FIELD
// !!! snake_case is not supported - adapt your models to use camelCase if necessary. !!!

// fieldName: used to build the errorCode (e.g. FIELD1_TOO_LONG)
// displayName: used to build the errorMessage (e.g. "Field1 is required")
// required: true if the field is NOT NULL in the database
// validationType: type of validation to apply (see ValidationType enum)

// length: used for ValidationType.STRING_LENGTH => max string length

// inclusiveMin: used for ValidationType.NUMERIC_BOUNDS => minimum accepted value
// exclusiveMax: used for ValidationType.NUMERIC_BOUNDS => upper bound (excluded)
// maxDecimals: used for ValidationType.NUMERIC_BOUNDS => max number of decimals
// Summary: inclusiveMin <= value < exclusiveMax

const $enumName = {
    // String fields
    FIELD1: createField({
        fieldName: 'FIELD1',
        displayName: 'Field1',
        required: true,
        validationType: ValidationType.STRING_LENGTH,
        length: 10
    }),
    FIELD2: createField({
        fieldName: 'FIELD2',
        displayName: 'Field2',
        required: false,
        validationType: ValidationType.STRING_LENGTH,
        length: 15
    }),

    // Numeric fields
    FIELD3: createField({
        fieldName: 'FIELD3',
        displayName: 'Field3',
        required: true,
        validationType: ValidationType.POSITIVE_INTEGER
    }),
    FIELD4: createField({
        fieldName: 'FIELD4',
        displayName: 'Field4',
        required: false,
        validationType: ValidationType.NUMERIC_BOUNDS,
        inclusiveMin: 0,
        exclusiveMax: 1000,
        maxDecimals: 2
    })
};
"@

    $createFunction = @"
function createField({fieldName, displayName, required, validationType, length, inclusiveMin, exclusiveMax, maxDecimals}) {
    
    const errorMessage = ErrorMessage[validationType]({
        displayName,
        length,
        inclusiveMin,
        exclusiveMax,
        maxDecimals
    });

    const errorCode = ErrorCode[validationType](fieldName);

    return {
        displayName,
        required,
        validationType,
        ...(length && { length }),
        ...(inclusiveMin !== undefined && { inclusiveMin }),
        ...(exclusiveMax !== undefined && { exclusiveMax }),
        ...(maxDecimals !== undefined && { maxDecimals }),
        errorMessage,
        errorCode
    };
}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $enumName };"
    } else {
        "module.exports = { $enumName };"
    }

    return "$importBlock`n`n$enumContent`n`n$createFunction`n`n$exportBlock"
}
#endregion

#region Get-FeatureRepositoryTemplate
function Get-FeatureRepositoryTemplate($moduleSystem, $structureType, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $repositoryName = "${capitalizedFeature}Repository"
    $criteriaConfigName = "${capitalizedFeature}CriteriaConfig"

    $repositoryImportPath = if ($structureType -eq "layer") {
        "./repository"
    } else {
        "../../shared/repositories/repository"
    }
    $criteriaImportPath = "./criteria/${feature}Criteria.config"

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { Repository } from "$repositoryImportPath.js";
import { $criteriaConfigName } from "$criteriaImportPath.js";
"@
    } else {
        @"
const { Repository } = require("$repositoryImportPath");
const { $criteriaConfigName } = require("$criteriaImportPath");
"@
    }

    $body = @"
class $repositoryName extends Repository {

    constructor() {
        super($criteriaConfigName);
    }
}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $repositoryName };"
    } else {
        "module.exports = { $repositoryName };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureRouterTemplate
function Get-FeatureRouterTemplate($moduleSystem, $structureType, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $controllerName = "${capitalizedFeature}Controller"
    $routerName = "${feature}Router"
    $controllerVar = "${feature}Controller"

    $controllerImportPath = if ($structureType -eq "layer") {
        "../controllers/$feature.controller"
    } else {
        "./$feature.controller"
    }

    $middlewareImportPath = if ($structureType -eq "layer") {
        "../middleware/params.validator"
    } else {
        "../../middleware/params.validator"
    }

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { $controllerName } from "$controllerImportPath.js";
import { idParamValidator } from "$middlewareImportPath.js";
import express from 'express';
"@
    } else {
        @"
const { $controllerName } = require("$controllerImportPath");
const { idParamValidator } = require("$middlewareImportPath");
const $routerName = require("express").Router();
"@
    }

    $body = if ($moduleSystem -eq "esm") {
        @"
const $controllerVar = new $controllerName();
const $routerName = express.Router();

$routerName.param("id", idParamValidator);

$routerName.post("/", $controllerVar.create);
$routerName.get("/", $controllerVar.get);
$routerName.get("/:id", $controllerVar.getById);
$routerName.patch("/:id", $controllerVar.update);
$routerName.put("/:id", $controllerVar.replace);
$routerName.delete("/:id", $controllerVar.remove);
"@
    } else {
        @"
const $controllerVar = new $controllerName();

$routerName.param("id", idParamValidator);

$routerName.post("/", $controllerVar.create);
$routerName.get("/", $controllerVar.get);
$routerName.get("/:id", $controllerVar.getById);
$routerName.patch("/:id", $controllerVar.update);
$routerName.put("/:id", $controllerVar.replace);
$routerName.delete("/:id", $controllerVar.remove);
"@
    }

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $routerName };"
    } else {
        "module.exports = { $routerName };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-FeatureServiceTemplate
function Get-FeatureServiceTemplate($moduleSystem, $structureType, $feature) {
    $capitalizedFeature = "$($feature.Substring(0,1).ToUpper())$($feature.Substring(1))"
    $serviceName = "${capitalizedFeature}Service"
    $repositoryName = "${capitalizedFeature}Repository"
    $fieldEnumName = "${capitalizedFeature}Field"

    $serviceImportPath = if ($structureType -eq "layer") { "./service" } else { "../../shared/services/service" }
    $validatorImportPath = if ($structureType -eq "layer") { "../validation/validator" } else { "../../shared/validation/validator" }
    $repositoryImportPath = if ($structureType -eq "layer") { "../repositories/$feature.repository" } else { "./$feature.repository" }
    $fieldEnumImportPath = if ($structureType -eq "layer") { "../validation/$feature" + "Field.enum" } else { "./validation/$feature" + "Field.enum" }

    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { Service } from "$serviceImportPath.js";
import { Validator } from "$validatorImportPath.js";
import { $repositoryName } from "$repositoryImportPath.js";
import { $fieldEnumName } from "$fieldEnumImportPath.js";
"@
    } else {
        @"
const { Service } = require("$serviceImportPath");
const { Validator } = require("$validatorImportPath");
const { $repositoryName } = require("$repositoryImportPath");
const { $fieldEnumName } = require("$fieldEnumImportPath");
"@
    }

    $body = @"
class $serviceName extends Service {

    constructor() {
        super(new $repositoryName(), new Validator($fieldEnumName));
    }

}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { $serviceName };"
    } else {
        "module.exports = { $serviceName };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}

#endregion

#region Get-HttpStatusEnumTemplate
function Get-HttpStatusEnumTemplate($moduleSystem) {
    $body = @"
const HttpStatus = {
    OK: 200,
    CREATED: 201,
    NO_CONTENT: 204,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    INTERNAL_SERVER_ERROR: 500
};
"@
    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { HttpStatus };"
    } else {
        "module.exports = { HttpStatus };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-LoggerTemplate
function Get-LoggerTemplate($moduleSystem) {
    $body = @"
const logger = (req, res, next) => {
    const start = new Date().getTime();
    const path = req.path;
    const border = "-----------------------------------------------------------------";
    console.log(border);
    console.log(``- Received request `${req.method} `${path}``);
    const queryParams = Object.entries(req.query);
    if (queryParams.length > 0) {
        console.log("- With query params :");
        queryParams.forEach(([key, value]) => {
            console.log(``-   `${key}: `${value}``);
        });
    }

    res.on("finish", () => {
        const duration = new Date().getTime() - start;
        console.log(``- Returned status `${res.statusCode} to request `${req.method} `${path} in `${duration} ms```);
        console.log(border);
    });

    next();
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { logger };"
    } else {
        "module.exports = { logger };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-ParamsValidatorTemplate
function Get-ParamsValidatorTemplate($moduleSystem) {
    $body = @"
const idParamValidator = (req, res, next, value) => {
    if (!/^[0-9]+$/.test(value)) {
        return res.status(400).json({ error: "id param must be numeric" });
    }

    next();
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { idParamValidator };"
    } else {
        "module.exports = { idParamValidator };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-RepositoryTemplateNoSequelize
function Get-RepositoryTemplateNoSequelize($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { criteriaBuilder } from "./criteria/criteriaBuilder.js";
import data from "./data.js";
"@
    } else {
        @"
const { criteriaBuilder } = require("./criteria/criteriaBuilder");
const data = require("./data");
"@
    }

    $body = @"
class Repository {

    constructor(criteriaConfig = {}) {
        if (new.target === Repository) {
            throw new Error("Repository is a base class and must be extended, not instantiated directly.");
        }
        this.criteriaConfig = criteriaConfig;
        this._memory = [...data]; // copy in memory
        this._idCounter = this._memory.length + 1;
    }

    findAll() {
        // TODO: replace by your own implementation
        return Promise.resolve(this._memory);
    }

    findWithCriteria(criteria) {
        const where = this.#buildWhereFromCriteria(criteria);

        // TODO: replace by your own implementation
        const filtered = this._memory.filter(item =>
            Object.values(where).every(fn => fn(item))
        );

        return Promise.resolve(filtered);
    }

    #buildWhereFromCriteria(criteria) {
        const whereClauses = [];

        for (const [key, value] of Object.entries(criteria)) {
            const config = this.criteriaConfig[key];
            if (config) {
                whereClauses.push({ config, value });
            }
        }

        return criteriaBuilder.buildFromWhereClauses(whereClauses);
    }

    findById(id) {
        // TODO: replace by your own implementation
        const entity = this._memory.find(item => item.id == id);
        return Promise.resolve(entity || null);
    }

    create(dto) {
        // TODO: replace by your own implementation
        const newEntity = { id: this._idCounter++, ...dto };
        this._memory.push(newEntity);
        return Promise.resolve();
    }

    update(entity, dto) {
        // TODO: replace by your own implementation
        const index = this._memory.findIndex(item => item.id === entity.id);
        if (index !== -1) {
            this._memory[index] = { ...this._memory[index], ...dto };
        }
        return Promise.resolve();
    }

    replace(entity, dto) {
        // TODO: replace by your own implementation
        const index = this._memory.findIndex(item => item.id === entity.id);
        if (index !== -1) {
            this._memory[index] = { id: entity.id, ...dto };
        }
        return Promise.resolve();
    }

    remove(entity) {
        // TODO: replace by your own implementation
        this._memory = this._memory.filter(item => item.id !== entity.id);
        return Promise.resolve();
    }

}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { Repository };"
    } else {
        "module.exports = { Repository };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-RepositoryTemplateSequelize
function Get-RepositoryTemplateSequelize($moduleSystem, $structureType, $feature) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { criteriaBuilder } from "./criteria/criteriaBuilder.js";
"@
    } else {
        @"
const { criteriaBuilder } = require("./criteria/criteriaBuilder");
"@
    }

    $body = @"
class Repository {

    constructor(model, criteriaConfig = {}) {
        if (new.target === Repository) {
            throw new Error("Repository is a base class and must be extended, not instantiated directly.");
        }
        this.model = model;
        this.criteriaConfig = criteriaConfig;
    }

    findAll() {
        return this.model.findAll();
    }

    findWithCriteria(criteria) {
        const where = this.#buildWhereFromCriteria(criteria);
        return this.model.findAll({ where });
    }

    #buildWhereFromCriteria(criteria) {
        const whereClauses = [];

        for (const [key, value] of Object.entries(criteria)) {
            const config = this.criteriaConfig[key];
            if (config) {
                whereClauses.push({ config, value });
            }
        }

        return criteriaBuilder.buildFromWhereClauses(whereClauses);
    }

    findById(id) {
        return this.model.findByPk(id);
    }

    create(dto) {
        return this.model.create(dto);
    }

    update(entity, dto) {
        return entity.update(dto);
    }

    replace(entity, dto) {
        return entity.set(dto).save();
    }

    remove(entity) {
        return entity.destroy();
    }

}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { Repository };"
    } else {
        "module.exports = { Repository };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-RoutesIndexTemplate
function Get-RoutesIndexTemplate($moduleSystem, $structureType, $features) {
    $importLines = @()
    $mountLines = @()

    foreach ($feature in $features) {
        $routerName = "${feature}Router"
        $routePath = "/${feature}s"

        $importPath = if ($structureType -eq "layer") {
            "./$feature.router"
        } else {
            "../../features/$feature/$feature.router"
        }

        if ($moduleSystem -eq "esm") {
            $importLines += "import { $routerName } from `"$importPath.js`";"
        } else {
            $importLines += "const { $routerName } = require(`"$importPath`");"
        }

        $mountLines += "mainRouter.use(`"$routePath`", $routerName);"
    }

    $importBlock = if ($moduleSystem -eq "esm") {
        $importLines + "import express from `"express`";" + "" + "const mainRouter = express.Router();"
    } else {
        $importLines + "const mainRouter = require(`"express`").Router();"
    }

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { mainRouter };"
    } else {
        "module.exports = { mainRouter };"
    }

    return ($importBlock + "" + $mountLines + "" + $exportBlock) -join "`n"
}
#endregion

#region Get-ServiceActionEnumTemplate
function Get-ServiceActionEnumTemplate($moduleSystem) {
    $body = @"
const ServiceAction = {
    CREATE: "CREATE",
    UPDATE: "UPDATE",
    REPLACE: "REPLACE",
    DELETE: "DELETE"
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { ServiceAction };"
    } else {
        "module.exports = { ServiceAction };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-ServiceResponseTemplate
function Get-ServiceResponseTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
@"
import { ServiceStatus } from "./serviceStatus.enum.js";
"@
    } else {
@"
const { ServiceStatus } = require("./serviceStatus.enum");
"@
    }
    $body = @"
const ok = (data) => {
    return { status: ServiceStatus.OK, data };
};

const notFound = (id) => {
    return { status: ServiceStatus.NOT_FOUND, error: ``Entity with ID `${id} not found`` };
};

const badRequest = (errors) => {
    return { status: ServiceStatus.BAD_REQUEST, errors };
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export const serviceResponse = { ok, notFound, badRequest };"
    } else {
        "module.exports = { serviceResponse: { ok, notFound, badRequest } };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-ServiceStatusEnumTemplate
function Get-ServiceStatusEnumTemplate($moduleSystem) {
    $body = @"
const ServiceStatus = {
    OK: "OK",
    NOT_FOUND: "NOT_FOUND",
    BAD_REQUEST: "BAD_REQUEST"
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { ServiceStatus };"
    } else {
        "module.exports = { ServiceStatus };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-ServiceTemplate
function Get-ServiceTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { serviceResponse } from "./serviceResponse.js";
import { ServiceAction } from "./serviceAction.enum.js";
"@
    } else {
        @"
const { serviceResponse } = require("./serviceResponse");
const { ServiceAction } = require("./serviceAction.enum");
"@
    }

    $body = @"
class Service {

    constructor(repository, validator) {
        if (new.target === Service) {
            throw new Error("Service is a base class and must be extended, not instantiated directly.");
        }
        this.repository = repository;
        this.validator = validator;
    }

    async get(criteria) {
        let result = null;

        if (Object.keys(criteria).length > 0) {
            result = await this.repository.findWithCriteria(criteria);
        } else {
            result = await this.repository.findAll();
        }

        return serviceResponse.ok(result);
    }

    async getById(id) {
        const entity = await this.repository.findById(id);

        if (!entity) {
            return serviceResponse.notFound(id);
        } else {
            return serviceResponse.ok(entity);
        }
    }

    async create(dto) {
        const errors = [
            ...this.validator.validateRequiredFields(dto),
            ...this.validator.validateValues(dto)
        ];
        return this.#performAction({ action: ServiceAction.CREATE, dto, errors });
    }

    async update(id, dto) {
        const entity = await this.repository.findById(id);

        if (!entity) {
            return serviceResponse.notFound(id);
        } else {
            const errors = this.validator.validateValues(dto);
            return this.#performAction({ action: ServiceAction.UPDATE, entity, dto, errors });
        }
    }

    async replace(id, dto) {
        const entity = await this.repository.findById(id);

        if (!entity) {
            return serviceResponse.notFound(id);
        } else {
            const errors = [
                ...this.validator.validateRequiredFields(dto),
                ...this.validator.validateValues(dto)
            ];
            return this.#performAction({ action: ServiceAction.REPLACE, entity, dto, errors });
        }
    }

    async remove(id) {
        const entity = await this.repository.findById(id);

        if (!entity) {
            return serviceResponse.notFound(id);
        } else {
            return this.#performAction({ action: ServiceAction.DELETE, entity });
        }
    }

    async #performAction({ action, entity, dto, errors = [] }) {
        if (errors.length === 0) {
            switch (action) {
                case ServiceAction.CREATE:
                    await this.repository.create(dto);
                    break;
                case ServiceAction.UPDATE:
                    await this.repository.update(entity, dto);
                    break;
                case ServiceAction.REPLACE:
                    await this.repository.replace(entity, dto);
                    break;
                case ServiceAction.DELETE:
                    await this.repository.remove(entity);
                    break;
            }
            return serviceResponse.ok();
        } else {
            return serviceResponse.badRequest(errors);
        }
    }
}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { Service };"
    } else {
        "module.exports = { Service };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-ValidationErrorCodeEnumTemplate
function Get-ValidationErrorCodeEnumTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
        @"
import { ValidationType } from "./validationType.enum.js";
"@
    } else {
        @"
const { ValidationType } = require("./validationType.enum");
"@
    }

    $body = @"
const ErrorCode = {
  [ValidationType.STRING_LENGTH]: (fieldName) =>
    ```${fieldName}_TOO_LONG``,

  [ValidationType.POSITIVE_INTEGER]: (fieldName) =>
    ```${fieldName}_NOT_POSITIVE_INTEGER``,

  [ValidationType.NUMERIC_BOUNDS]: (fieldName) =>
    ```${fieldName}_OUT_OF_BOUNDS``
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { ErrorCode };"
    } else {
        "module.exports = { ErrorCode };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-ValidationErrorMessageEnumTemplate
function Get-ValidationErrorMessageEnumTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
@"
import { ValidationType } from "./validationType.enum.js";
"@
    } else {
@"
const { ValidationType } = require("./validationType.enum");
"@
    }

    $body = @"
const ErrorMessage = {
  [ValidationType.STRING_LENGTH]: ({ displayName, length }) =>
    ```${displayName} must be max `${length} characters long.``,
    
  [ValidationType.POSITIVE_INTEGER]: ({ displayName }) =>
    ```${displayName} must be a positive integer.``,
    
  [ValidationType.NUMERIC_BOUNDS]: ({ displayName, inclusiveMin, exclusiveMax, maxDecimals }) =>
    ```${displayName} must be between `${inclusiveMin} and `${exclusiveMax} (not included) with max `${maxDecimals} digits after the decimal point.``
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { ErrorMessage };"
    } else {
        "module.exports = { ErrorMessage };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

#region Get-ValidationTypeEnumTemplate
function Get-ValidationTypeEnumTemplate($moduleSystem) {
    $body = @"
// This enum represents the type of validation you want to be able to apply when creating or modifying an object.
// You can easily add your own types by providing validator.js with an implementation for them.
const ValidationType = {
    STRING_LENGTH: "STRING_LENGTH",
    NUMERIC_BOUNDS: "NUMERIC_BOUNDS",
    POSITIVE_INTEGER: "POSITIVE_INTEGER"
};
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { ValidationType };"
    } else {
        "module.exports = { ValidationType };"
    }

    return "$body`n`n$exportBlock"
}
#endregion

#region Get-ValidatorTemplate
function Get-ValidatorTemplate($moduleSystem) {
    $importBlock = if ($moduleSystem -eq "esm") {
@"
import { ValidationType } from "./validationType.enum.js";
"@
    } else {
@"
const { ValidationType } = require("./validationType.enum");
"@
    }

    $body = @"
class Validator {

    #fieldEnum;

    constructor(fieldEnum) {
        this.#fieldEnum = fieldEnum;
    }

    validateRequiredFields(obj) {
        const missingFields = [];

        for (const [enumName, config] of Object.entries(this.#fieldEnum)) {
            if (config.required) {
                const fieldName = this.#toCamelCase(enumName);
                const value = obj[fieldName];
                if (value === undefined || value === null || value === "") {
                    missingFields.push({
                        field: fieldName,
                        type: "missing",
                        message: ``Missing required field: `${fieldName}``
                    });
                }
            }
        }

        return missingFields;
    }

    validateValues(obj) {
        const invalidValues = [];

        for (const [key, value] of Object.entries(obj)) {
            const field = this.#fieldEnum[this.#toConstantCase(key)];
            if (field && !this.#isValid(field, value)) {
                invalidValues.push({
                    field: key,
                    type: "invalid",
                    message: field.errorMessage,
                    code: field.errorCode
                });
            }
        }

        return invalidValues;
    }

    #isValid(field, value) {
        switch (field.validationType) {
            case ValidationType.STRING_LENGTH:
                return this.#validateStringLength(field, value);
            case ValidationType.POSITIVE_INTEGER:
                return this.#validatePositiveInteger(value);
            case ValidationType.NUMERIC_BOUNDS:
                return this.#validateNumericBounds(field, value);
            default:
                return false;
        }
    }

    #validateStringLength(field, value) {
        return typeof value === "string" && value.length <= field.length;
    }

    #validatePositiveInteger(value) {
        return Number.isInteger(value) && value > 0;
    }

    #validateNumericBounds(field, value) {
        const isValidRange =
            typeof value === "number" &&
            value >= field.inclusiveMin &&
            value < field.exclusiveMax;

        const decimals = value.toString().split(".")[1];
        const isValidDecimals = !decimals || decimals.length <= field.maxDecimals;

        return isValidRange && isValidDecimals;
    }

    #toCamelCase(str) {
        return str
            .toLowerCase()
            .split("_")
            .map((word, index) =>
                index === 0 ? word : word.charAt(0).toUpperCase() + word.slice(1)
            )
            .join("");
    }

    #toConstantCase(str) {
        return str
            .replace(/([a-z0-9])([A-Z])/g, "`$1_`$2")
            .toUpperCase();
    }

}
"@

    $exportBlock = if ($moduleSystem -eq "esm") {
        "export { Validator };"
    } else {
        "module.exports = { Validator };"
    }

    return "$importBlock`n`n$body`n`n$exportBlock"
}
#endregion

Export-ModuleMember -Function `
    Get-ApiResponseTemplate, `
    Get-AppTemplate, `
    Get-ControllerTemplate, `
    Get-CriteriaBuilderNoSequelizeTemplate, `
    Get-CriteriaTypeEnumTemplate, `
    Get-DataTemplate, `
    Get-ErrorHandlerTemplate, `
    Get-FeatureControllerTemplate, `
    Get-FeatureCriteriaConfigTemplate, `
    Get-FeatureCriteriaEnumTemplate, `
    Get-FeatureFieldEnumTemplate, `
    Get-FeatureRepositoryTemplate, `
    Get-FeatureRouterTemplate, `
    Get-FeatureServiceTemplate, `
    Get-HttpStatusEnumTemplate, `
    Get-LoggerTemplate, `
    Get-ParamsValidatorTemplate, `
    Get-RepositoryTemplateNoSequelize, `
    Get-RepositoryTemplateSequelize, `
    Get-RoutesIndexTemplate, `
    Get-ServiceActionEnumTemplate, `
    Get-ServiceResponseTemplate, `
    Get-ServiceStatusEnumTemplate, `
    Get-ServiceTemplate, `
    Get-ValidationErrorCodeEnumTemplate, `
    Get-ValidationErrorMessageEnumTemplate, `
    Get-ValidationTypeEnumTemplate, `
    Get-ValidatorTemplate