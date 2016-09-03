/*
 *	Copyright 2015, SmugWimp
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors 
 *	may be used to endorse or promote products derived from this software without specific 
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */
package com.buzzTouch;

import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.location.Location;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.MapFragment;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;


public class SW_smugAware extends BT_fragment{

    //data vars..
    private DownloadScreenDataWorker downloadScreenDataWorker;
    public MapFragment mapFragment = null;
    public GoogleMap mapView = null;
    public ArrayList<BT_item> childItems;
    public ArrayList<Marker> markers;
    public Map<String, Integer> markerIndexes;
    public Marker deviceMarker = null;
    public Bitmap sharedBitmap = null;
    public String JSONData = "";
    
    //properties from JSON
    public String dataURL = "";
    public String saveAsFileName = "";
    public String showUserLocation = "";
    public String showUserLocationButton = "";
    public String defaultMapType = "";
    public String showMapTypeButtons = "";
    public String showRefreshButton = "";
    public String singleLocationDefaultZoom = "";
    public String allowShareScreenshot = "";
    private long startTime = 0;
    
    
    

    //onCreateView...
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,  Bundle savedInstanceState){
	       
		/*
			Note: fragmentName property is already setup in the parent class (BT_fragment). This allows us 
			to add the 	name of this class file to the LogCat console using the BT_debugger.
		*/
		//show life-cycle event in LogCat console...
		BT_debugger.showIt(fragmentName + ":onCreateView JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
	
		//inflate the layout file for this screen...
		View thisScreensView = inflater.inflate(R.layout.sw_smugaware, container, false);

        //may not have google maps requirements...
        boolean hasAPIKeyInManifest = false;
        boolean deviceHasGooglePlayServices = false;
        boolean projectHasGooglePlayServicesReference = true;
        
        //get the com.google.android.maps.v2.API_KEY from the AndroidManifest.xml file...
        ApplicationInfo ai = null;
        String tmpAPIKey = "";
        try{
            ai = guamflights_appDelegate.getApplication().getPackageManager().getApplicationInfo(guamflights_appDelegate.getApplication().getPackageName(), PackageManager.GET_META_DATA);
            tmpAPIKey = (String)ai.metaData.get("com.google.android.maps.v2.API_KEY");
        }catch(Exception e) {
            BT_debugger.showIt(fragmentName + ":onCreate. EXCEPTION. Google Maps v2 API Key not found in AndroidManifest?");
        }
        if(tmpAPIKey.length() < 1 || tmpAPIKey.equalsIgnoreCase("GOOGLE_MAPS_FOR_ANDROID_V2_API_KEY_GOES_HERE")){
            BT_debugger.showIt(fragmentName + ":onCreate. Google Maps v2 API Key not found in AndroidManifest?");
        }else{
            hasAPIKeyInManifest = true;
            BT_debugger.showIt(fragmentName + ":onCreate. Found Google Maps v2 API Key: " + tmpAPIKey);
        }
        
        //see if device is ok...
        try{
            int status = GooglePlayServicesUtil.isGooglePlayServicesAvailable(guamflights_appDelegate.getApplication());
            if(status == ConnectionResult.SUCCESS){
                deviceHasGooglePlayServices = true;
            }
        }catch(Exception e){
            projectHasGooglePlayServicesReference = false;
            BT_debugger.showIt(fragmentName + ":onCreateView EXCEPTION (1) " + e.toString());
        }
        
        //continue only if we found the necessary requirements for google maps....
        if(hasAPIKeyInManifest && deviceHasGooglePlayServices && projectHasGooglePlayServicesReference){
            
            
            //try/catch required...
            try{
                
                //inflate the view for this screen (the xml holding the google map)...
                //                thisScreensView = inflater.inflate(R.layout.bt_screen_map, container, false);
                
                //init properties from JSON data...
                childItems = new ArrayList<BT_item>();
                markers = new ArrayList<Marker>();
                markerIndexes = new HashMap<String, Integer>();
                dataURL = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "dataURL", "");
                //
                saveAsFileName = this.screenData.getItemId() + "_screenData.txt";
                
                showUserLocation = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "showUserLocation", "0");
                showUserLocationButton = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "showUserLocationButton", "0");
                defaultMapType = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "defaultMapType", "default");
                showMapTypeButtons = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "showMapTypeButtons", "1");
                showRefreshButton = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "showRefreshButton", "0");
                singleLocationDefaultZoom = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "singleLocationDefaultZoom", "15");
                allowShareScreenshot = BT_strings.getJsonPropertyValue(this.screenData.getJsonObject(), "allowShareScreenshot", "0");
                
                if (BT_fileManager.doesCachedFileExist(saveAsFileName)) {
                    BT_fileManager.deleteFile(saveAsFileName);
                }
                
                //get reference to the map in the screen_map.xml file...
                mapView = ((MapFragment) getFragmentManager().findFragmentById(R.id.mapView)).getMap();
                LatLng latLng = new LatLng(13.684219, 144.956665);  // Center of Airport Runway
                CameraUpdate cameraUpdate = CameraUpdateFactory.newLatLngZoom(latLng, 8);
                mapView.animateCamera(cameraUpdate);
                
                
                
            }catch(java.lang.NoClassDefFoundError e){
                BT_debugger.showIt(fragmentName + ":onCreateView EXCEPTION (2) " + e.toString());
            }
        }
        
        //return the layout file or null if we don't have Google maps configured...
        return thisScreensView;
        
    }//onCreateView...
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //onStart...
    @Override
    public void onStart(){
        super.onStart();
        //show life-cycle event in LogCat console...
        if(screenData != null){
            BT_debugger.showIt(fragmentName + ":onStart JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
        }
        //
        
        
    }
    
    
    /* Start:
     startTime = System.currentTimeMillis();
     timerHandler.postDelayed(timerRunnable, 0);
     */
    /* Stop:
     timerHandler.removeCallbacks(timerRunnable);
     */
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //onResume...
    @Override
    public void onResume() {
        super.onResume();
        //show life-cycle event in LogCat console...
        if(screenData != null){
            BT_debugger.showIt(fragmentName + ":onResume JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
        }
        //
        startTime = System.currentTimeMillis();
        timerHandler.postDelayed(timerRunnable, 0);
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //onPause...
    @Override
    public void onPause() {
        super.onPause();
        
        //show life-cycle event in LogCat console...
        if(screenData != null){
            BT_debugger.showIt(fragmentName + ":onPause JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
        }
        //
        timerHandler.removeCallbacks(timerRunnable);
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //onStop...
    @Override
    public void onStop(){
        super.onStop();
        
        //show life-cycle event in LogCat console...
        if(screenData != null){
            BT_debugger.showIt(fragmentName + ":onStop JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
        }
        //
        timerHandler.removeCallbacks(timerRunnable);
        if(downloadScreenDataWorker != null){
            boolean retry = true;
            downloadScreenDataWorker.setThreadRunning(false);
            while(retry){
                try{
                    downloadScreenDataWorker.join();
                    retry = false;
                }catch (Exception je){
                }
            }
        }
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //onDestroy...
    @Override
    public void onDestroy() {
        super.onDestroy();
        
        //show life-cycle event in LogCat console...
        if(screenData != null){
            BT_debugger.showIt(fragmentName + ":onDestroy JSON itemId: \"" + screenData.getItemId() + "\" itemType: \"" + screenData.getItemType() + "\" itemNickname: \"" + screenData.getItemNickname() + "\"");
        }
        //
        
    }
    
    
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    @Override
    public void onDestroyView() {
        super.onDestroyView();
        BT_debugger.showIt(fragmentName + ":onDestroyView");
        timerHandler.removeCallbacks(timerRunnable);
        MapFragment destroyMap = (MapFragment)getFragmentManager().findFragmentById(R.id.mapView);
        if(destroyMap != null){
            
            //remember camera position so we can re-zoom when coming back...
            CameraPosition mMyCam = mapView.getCameraPosition();
            double latitude = mMyCam.target.latitude;
            double longitude = mMyCam.target.longitude;
            float zoom = mMyCam.zoom;
            
            BT_strings.setPrefString(this.screenData.getItemId() + "_lastLatitude", String.valueOf(latitude));
            BT_strings.setPrefString(this.screenData.getItemId() + "_lastLongitude", String.valueOf(longitude));
            BT_strings.setPrefString(this.screenData.getItemId() + "_lastZoom", String.valueOf(zoom));
            
            //destroy the map...
            getFragmentManager().beginTransaction().remove(destroyMap).commit();
            
        }
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //refresh screenData
    public void refreshScreenData(){
        BT_debugger.showIt(fragmentName + ":refreshScreenData");
        
        if(dataURL.length() > 1){
            
            if (BT_fileManager.doesCachedFileExist(saveAsFileName)) {
                BT_fileManager.deleteFile(saveAsFileName);
            }
            
            //download data...
            downloadScreenDataWorker = new DownloadScreenDataWorker();
            downloadScreenDataWorker.setDownloadURL(dataURL);
            downloadScreenDataWorker.setSaveAsFileName(saveAsFileName);
            downloadScreenDataWorker.setThreadRunning(true);
            downloadScreenDataWorker.start();
            
        }else{
            BT_debugger.showIt(fragmentName + ":refreshScreenData NO DATA URL for this screen? Not downloading.");
            showPlanes();
        }
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //show map type
    public void showMapType(String theMapType){
        BT_debugger.showIt(fragmentName + ":showMapType \"" + theMapType + "\"");
        //standard, terrain, hybrid
        mapView.setMapType(GoogleMap.MAP_TYPE_NORMAL);
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    public void getFlightInfo() {
        
        
        
        
        
    }
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //parse screenData...
    public void parseScreenData(String theJSONString){
        BT_debugger.showIt(fragmentName + ":parseScreenData");
        
        //        theJSONString = "";
        //parse JSON string
        try{
            
            //empty data if previously filled...
            childItems.clear();
            markers.clear();
            theJSONString = "{\"childItems\": " + theJSONString + "}";
            BT_debugger.showIt("theJsonString: " + theJSONString);
            //if theJSONString is empty, look for child items in this screen's config data..
            JSONArray items = null;
            
            JSONObject raw = new JSONObject(theJSONString);
            if(raw.has("childItems")){
                items =  raw.getJSONArray("childItems");
            }
            //loop items..
            if(items != null){
                for (int i = 0; i < items.length(); i++){
                    
                    JSONObject tmpJson = items.getJSONObject(i);
                    BT_item tmpItem = new BT_item();
                    tmpItem.setItemId(tmpJson.getString("hex"));
                    tmpItem.setItemType("swPlaneItem");
                    
                    //check for valid entries in a minute...
                    String tmpLatitude = "";
                    String tmpLongitude = "";
                    
                    //title..
                    if(tmpJson.has("flight")) {
                        tmpItem.setItemNickname(tmpJson.getString("flight"));
                    }
                    
                    //subTitle...
                    if(tmpJson.has("hex")){
                        //                        tmpItem.setItemType(tmpJson.getString("hex"));
                    }
                    
                    //latitude...
                    if(tmpJson.has("lat")) {
                        //                        tmpItem.setItemType(tmpJson.getString("subTitle"));
                        tmpLatitude = tmpJson.getString("lat");
                    }
                    if(tmpJson.has("lon")){
                        //                       tmpItem.setItemType(tmpJson.getString("lon"));
                        tmpLongitude = tmpJson.getString("lon");
                    }
                    
                    //remember it only if we have location...
                    if(tmpLatitude.length() > 4 && tmpLongitude.length() > 4){
                        
                        //remember the child item...
                        tmpItem.setJsonObject(tmpJson);
                        childItems.add(tmpItem);
                        
                    }
                    
                    
                }//for
                
                
            }else{
                BT_debugger.showIt(fragmentName + ":parseScreenData NO CHILD ITEMS?");
                
            }
        }catch(Exception e){
            BT_debugger.showIt(fragmentName + ":parseScreenData EXCEPTION " + e.toString());
        }
        
        //show how many items...
        //        if(childItems.size() > 0){
        //            showToast(childItems.size() + " " + getString(R.string.mapLocations), "short");
        //        }
        
        //show pins here after parsing data...
        showPlanes();
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //show map pins...
    public void showPlanes(){
        BT_debugger.showIt(fragmentName + ":showPlanes");
        
        mapView.clear();
        showMapType(defaultMapType);
        
        //add the markers to the map...
        int i = 0;
        for (i = 0; i < childItems.size(); i++){
            BT_item thisLocation = childItems.get(i);
            String mySquawk = BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(),"squawk","");
            int pinGraphicResId;
            if ( mySquawk == "7500") {
                pinGraphicResId = R.drawable.sw_airemergency;
            } else {
                pinGraphicResId = R.drawable.sw_aircraft;
            }
            
            String tmpLatitude = BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(), "lat", "");
            String tmpLongitude = BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(), "lon", "");
            if(tmpLatitude.length() > 4 && tmpLongitude.length() > 4){
                MarkerOptions tmpMarkerOptions = new MarkerOptions()
                .position(new LatLng(Double.parseDouble(tmpLatitude), Double.parseDouble(tmpLongitude)))
                .title(BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(), "itemNickname", ""))
                .snippet(BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(), "itemId", ""))
                .draggable(false)
                .anchor(0.5f,0.5f)
                .rotation(Float.valueOf(BT_strings.getJsonPropertyValue(thisLocation.getJsonObject(), "track","")))
                .icon(BitmapDescriptorFactory.fromResource(pinGraphicResId));
                
                //add to map and keep track of the marker..
                Marker tmpMarker = mapView.addMarker(tmpMarkerOptions);
                markers.add(tmpMarker);
                
                //remember the id and index of this marker so we can determine what marker was tapped later...
                markerIndexes.put(tmpMarker.getId().toString(), i);
                
            }//have lat/lon...
            
        }//end for each location on the map...
        
        //we must have a device location in order to show the user on the map...
        String tmpLatitude = guamflights_appDelegate.rootApp.getRootDevice().getDeviceLatitude();
        String tmpLongitude = guamflights_appDelegate.rootApp.getRootDevice().getDeviceLongitude();
        if(tmpLatitude.length() > 4 && showUserLocation.equalsIgnoreCase("1")){
            
            MarkerOptions tmpMarkerOptions = new MarkerOptions()
            .position(new LatLng(Double.parseDouble(tmpLatitude), Double.parseDouble(tmpLongitude)))
            .title(getString(R.string.mapUserLocationTitle))
            .snippet(guamflights_appDelegate.rootApp.getRootDevice().getDeviceModel())
            .draggable(false)
            .icon(BitmapDescriptorFactory.fromResource(R.drawable.bt_screen_map_youarehere));
            
            //add the device's marker to the map...
            deviceMarker = mapView.addMarker(tmpMarkerOptions);
            markers.add(deviceMarker);
            
            //remember the device's location as -1 so we know when it's tapped...
            markerIndexes.put(deviceMarker.getId().toString(), -1);
            
            //turn off the standard user-location marker...
            mapView.setMyLocationEnabled(false);
            
        }
        
        ///////////////////////////////////////////////
        ///////////////////////////////////////////////
        //setOnMarkerClickListener for location taps (prevent default callout bubble)...
        mapView.setOnMarkerClickListener(new GoogleMap.OnMarkerClickListener(){
            public boolean onMarkerClick(Marker marker){
                
                //use the item id to figure out what "index" this marker is...
                int markerIndex = markerIndexes.get(marker.getId().toString());
                BT_debugger.showIt(fragmentName + ":OnMarkerClickListener Marker Index: " + markerIndex);
                
                //pass index of this marker to handleMarkerClick method...
                handleMarkerClick(markerIndex);
                
                //return true prevents default callout bubble...
                return true;
            }
            
        });
        
        //set the map's bounds...
        
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //handleMarkerClick..
    public void handleMarkerClick(final int markerIndex) {
        BT_debugger.showIt(fragmentName + ":handleMarkerClick");
        
        //vars used in callout bubble...
        BT_item tappedItem = null;
        String latitude = "";
        String longitude = "";
        String title = "";
        String subTitle = "";
        String loadScreenWithItemId = "";
        String loadScreenWithNickname = "";
        String calloutTapChoice = "";
        Drawable pinGraphic = null;
        
        tappedItem = childItems.get(markerIndex);
        latitude = BT_strings.getJsonPropertyValue(tappedItem.getJsonObject(), "lat", "");
        longitude = BT_strings.getJsonPropertyValue(tappedItem.getJsonObject(), "lon", "");
        title = "Selected Aircraft"; // BT_strings.getJsonPropertyValue(tappedItem.getJsonObject(), "flight", "");
        subTitle = BT_strings.getJsonPropertyValue(tappedItem.getJsonObject(), "flight", "");
        pinGraphic = getResources().getDrawable(R.drawable.sw_aircraft);
        BT_debugger.showIt(fragmentName + ":handleMarkerClick. Tapped: \"" + title + "\"");
        
        final AlertDialog myAlert = new AlertDialog.Builder(this.getActivity()).create();
        myAlert.setTitle(title);
        myAlert.setMessage(subTitle);
        myAlert.setIcon(pinGraphic);
        myAlert.setCancelable(false);
        myAlert.setButton2(getString(R.string.ok), new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                myAlert.dismiss();
            } });
        
        myAlert.show();
    }
    
    ///////////////////////////////////////////////
    ///////////////////////////////////////////////
    //DownloadScreenDataThread and Handler
    Handler downloadScreenDataHandler = new Handler(){
    @Override public void handleMessage(Message msg){
    hideProgress();
    if(JSONData.length() < 1){
        // showAlert(getString(R.string.errorTitle), getString(R.string.errorDownloadingData));
    }else{
        //                BT_debugger.showIt("downloadJsonData: " + JSONData);
        parseScreenData(JSONData);
    }
}
};

///////////////////////////////////////////////
///////////////////////////////////////////////
public class DownloadScreenDataWorker extends Thread{
    boolean threadRunning = false;
    String downloadURL = "";
    String saveAsFileName = "";
    void setThreadRunning(boolean bolRunning){
        threadRunning = bolRunning;
    }
    void setDownloadURL(String theURL){
        downloadURL = theURL;
    }
    void setSaveAsFileName(String theFileName){
        saveAsFileName = theFileName;
    }
    @Override
    public void run(){
        
        //downloader will fetch and save data..Set this screen data as "current" to be sure the screenId
        //in the URL gets merged properly. Several screens could be loading at the same time...
        guamflights_appDelegate.rootApp.setCurrentScreenData(screenData);
        String useURL = BT_strings.mergeBTVariablesInString(dataURL);
        BT_debugger.showIt(fragmentName + ":downloading screen data from " + useURL);
        BT_downloader objDownloader = new BT_downloader(useURL);
        objDownloader.setSaveAsFileName(saveAsFileName);
        JSONData = objDownloader.downloadTextData();
        
        //save JSONData...
        BT_fileManager.saveTextFileToCache(JSONData, saveAsFileName);
        
        //send message to handler..
        this.setThreadRunning(false);
        downloadScreenDataHandler.sendMessage(downloadScreenDataHandler.obtainMessage());
        
    }
}
//END DownloadScreenDataThread and Handler
///////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
///////////////////////////////////////////////

/* Start:
 startTime = System.currentTimeMillis();
 timerHandler.postDelayed(timerRunnable, 0);
 */
/* Stop:
 timerHandler.removeCallbacks(timerRunnable);
 */
//runs without a timer by reposting this handler at the end of the runnable
Handler timerHandler = new Handler();
Runnable timerRunnable = new Runnable() {
@Override
public void run() {
long millis = System.currentTimeMillis() - startTime;
int seconds = (int) (millis / 1000);
int minutes = seconds / 60;
seconds = seconds % 60;
///////////////////////
refreshScreenData(); //
///////////////////////
timerHandler.postDelayed(this, 500);
}
};





///////////////////////////////////////////////
///////////////////////////////////////////////
///////////////////////////////////////////////
////////                           ////////////
} //////     End of Class File     ////////////
////////                           ////////////
///////////////////////////////////////////////




