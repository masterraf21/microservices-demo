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
	"math/rand"
	"time"
)

type Ad struct {
	Text     string   `json:"text"`
	Redirect string   `json:"redirect_url"`
	Tags     []string `json:"tags"`
}

type adserviceServer struct {
	adFile   string
	ads      []Ad
	adsIndex map[string][]int
}

func (a *adserviceServer) loadAdsFile() error {
	data, err := ioutil.ReadFile(a.adFile)
	if err != nil {
		return err
	}
	err = json.Unmarshal(data, &a.ads)
	if err != nil {
		return err
	}
	fmt.Printf("found %d ads\n", len(a.ads))

	// index ads by tags
	a.indexAds()

	return nil
}

// indexAds index ads by tags
func (a *adserviceServer) indexAds() {
	for i, ad := range a.ads {
		for _, tag := range ad.Tags {
			a.adsIndex[tag] = append(a.adsIndex[tag], i)
		}
	}
}

// getRandomAds return a random ad
func (a *adserviceServer) getRandomAds() []Ad {
	rand.Seed(time.Now().Unix())
	n := rand.Int() % len(a.ads)

	return a.ads[n : n+1]
}

// getAdsByCategory return all ads in a category
func (a *adserviceServer) getAdsByCategory(tag string) []Ad {
	ads := []Ad{}

	for _, ad := range a.adsIndex[tag] {
		ads = append(ads, a.ads[ad])
	}
	return ads
}
