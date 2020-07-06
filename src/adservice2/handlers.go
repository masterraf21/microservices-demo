// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

// isReturnError returns true until the error counter is at zero
// if we configure consecutiveError to be 3, we will return true 3 times, then false
func (a *adserviceServer) isReturnError() bool {
	a.Lock()
	defer a.Unlock()
	if a.failCounter > 0 {
		a.failCounter--
		return true
	}
	a.failCounter = a.failCount
	return false
}

// randomAdHandler return a random add
// r.HandleFunc("/ad", a.randomAdHandler)
func (a *adserviceServer) randomAdHandler(w http.ResponseWriter, r *http.Request) {
	if a.isReturnError() {
		respondWithError(w, http.StatusServiceUnavailable, "error forced by consecutiveError counter")
		return
	}

	ads := a.getRandomAds()
	respondWithJSON(w, http.StatusOK, ads)
}

// categoryAdHandler return all ads from a category
// r.HandleFunc("/ads/{category}", a.categoryAdHandler)
func (a *adserviceServer) categoryAdHandler(w http.ResponseWriter, r *http.Request) {
	if a.isReturnError() {
		respondWithError(w, http.StatusServiceUnavailable, "error forced by consecutiveError counter")
		return
	}

	vars := mux.Vars(r)
	cat := vars["category"]

	ads := a.getAdsByCategory(cat)
	respondWithJSON(w, http.StatusOK, ads)
}

// respondWithJSON write a payload as JSON in a HTML page
func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		fmt.Println(err)
	}

	time.Sleep(*extraLatency)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(response)
}

// respondWithError return an error encoded in JSON format
func respondWithError(w http.ResponseWriter, code int, message string) {
	respondWithJSON(w, code, map[string]string{"error": message})
}
