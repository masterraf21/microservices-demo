package main

import "testing"

func TestGetRandomAds(t *testing.T) {

	ads := []Ad{
		{
			Text:     "a",
			Redirect: "/a",
			Tags:     []string{"a", "b"},
		},
		{
			Text:     "b",
			Redirect: "/b",
			Tags:     []string{"a", "b"},
		},
		{
			Text:     "c",
			Redirect: "/c",
			Tags:     []string{"c"},
		},
	}

	adservice := adserviceServer{
		adFile:   "none",
		ads:      ads,
		adsIndex: make(map[string][]int),
	}

	adservice.indexAds()
	rndAd := adservice.getRandomAds()
	if len(rndAd) == 0 {
		t.Errorf("random add not received. got %v", rndAd)
	}
}

func TestGetAdsByCategory(t *testing.T) {

	ads := []Ad{
		{
			Text:     "a",
			Redirect: "/a",
			Tags:     []string{"a", "b"},
		},
		{
			Text:     "b",
			Redirect: "/b",
			Tags:     []string{"a", "b"},
		},
		{
			Text:     "c",
			Redirect: "/c",
			Tags:     []string{"c"},
		},
	}

	adservice := adserviceServer{
		adFile:   "none",
		ads:      ads,
		adsIndex: make(map[string][]int),
	}

	adservice.indexAds()
	AdsByCat := adservice.getAdsByCategory("a")
	if len(AdsByCat) != 2 {
		t.Errorf("getAdsByCategory returned %d, should get %d", len(AdsByCat), 2)
	}
}
