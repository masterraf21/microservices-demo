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
	"io/ioutil"
)

// var Ads []Ad

// type Ad []struct {
// 	Text     string   `json:"text"`
// 	Redirect string   `json:"redirect"`
// 	Tags     []string `json:"tags"`
// }

type Ads []struct {
	Text     string   `json:"text"`
	Redirect string   `json:"redirect"`
	Tags     []string `json:"tags"`
}

type adserviceServer struct {
	adFile string
	ads    Ads
}

func (a *adserviceServer) loadAdsFile() {

	data, err := ioutil.ReadFile(a.adFile)
	if err != nil {
		fmt.Print(err)
	}
	err = json.Unmarshal(data, &a.ads)
	if err != nil {
		fmt.Println("error:", err)
	}
}

func (*adserviceServer) getRandomAds() {}

// func (*adserviceServer) getAdsByCategory(tag string) Ad {
// 	var ad Ad

// 	return ad
// }
