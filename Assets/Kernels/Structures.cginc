// Copyright 2018 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
// Glue to make data types work.
//
#define vec2 float2
#define vec3 float3
#define vec4 float4

#define FLT_MAX         3.402823466e+38F

// ---------------------------------------------------------------------------------------------- //
// Ray Tracing Structures.
// ---------------------------------------------------------------------------------------------- /

struct Ray {
  vec3 origin;
  vec3 direction;
  vec3 color;
  vec4 accumColor;
  int  bounces;
  int  material;

  vec3 PointAtParameter(float t) {
	  return origin + t * direction;
  }
};

struct HitRecord {
  vec2  uv;
  float t;
  vec3  p;
  vec3  normal;
  vec3  albedo;
  int   material;
};

struct Sphere {
  vec3  center; 
  float radius;
  int   material;
  vec3  albedo;

  bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
};

struct Plane
{
	vec3 center;
	float scale;
	int material;
	vec3 albedo;

	bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
 };

 
struct Cube
{
	vec3 center;
	float scale;
	int material;
	vec3 albedo;

	bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
};


struct Triangle
{
	vec3 v0;
	vec3 v1;
	vec3 v2;
	vec3 normal;
	int material;
	vec3 albedo;

	bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
};


bool Sphere::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  vec3 oc = r.origin - center;
  float a = dot(r.direction, r.direction);
  float b = dot(oc, r.direction);
  float c = dot(oc, oc) - radius * radius;
  float discriminant = b*b - a*c;

  if (discriminant <= 0)  {
    return false;
  }
    
  float temp = (-b - sqrt(b*b - a*c)) / a;
  if (temp < tMax && temp > tMin) {
    rec.t = temp;
    rec.p = r.PointAtParameter(rec.t);
    rec.normal = normalize((rec.p - center) / radius);
    return true;
  }

  temp = (-b + sqrt(b*b - a*c)) / a;
  if (temp < tMax && temp > tMin) {
    rec.t = temp;
    rec.p = r.PointAtParameter(rec.t);
    rec.normal = normalize((rec.p - center) / radius);
    return true;
  }

  return false;
}

// Assumption : Plane is not rotated, Camera is in +y
bool Plane::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
	
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  vec3 pn = vec3(0, 1, 0);
  float denom = dot(r.direction, pn);
  if (abs(denom) > 0)
  {
	vec3 oc = r.origin - center;
	float temp = dot(oc, pn) / denom;
	if (temp <= 0) 
	{
		rec.t = temp;
		rec.p = r.PointAtParameter(rec.t);
		rec.normal = pn;
		return true;
	}	
  }

  return false;
}

// Assumption : Same scale for all x, y, z 
bool Cube::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
	
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  float s = 0.5 * scale;

  vec3 minPos = center - vec3(s, s, s);
  vec3 maxPos = center + vec3(s, s, s);

  float tmin = (minPos.x - r.origin.x) / r.direction.x; 
  float tmax = (maxPos.x - r.origin.x) / r.direction.x; 
 
  if (tmin > tmax) // Swap
  {
	float temp = tmin;
	tmin = tmax;
	tmax = temp;
  }
 
  float tymin = (minPos.y - r.origin.y) / r.direction.y; 
  float tymax = (maxPos.y - r.origin.y) / r.direction.y; 
 
  if (tymin > tymax) // Swap
  {
	float temp = tymin;
	tymin = tymax;
	tymax = temp;
  }
 
  if ((tmin > tymax) || (tymin > tmax)) 
      return false; 
 
  if (tymin > tmin)
	tmin = tymin; 

  if (tymax < tmax) 
      tmax = tymax; 
 

  float tzmin = (minPos.z - r.origin.z) / r.direction.z; 
  float tzmax = (maxPos.z - r.origin.z) / r.direction.z; 
 
  if (tzmin > tzmax) // Swap
  {
	float temp = tzmin;
	tzmin = tzmax;
	tzmax = temp;
  }
 
  if ((tmin > tzmax) || (tzmin > tmax)) 
      return false; 
 
  if (tzmin > tmin) 
	tmin = tzmin; 
      
  if (tzmax < tmax) 
      tmax = tzmax; 
 
  rec.t = tmin;
  rec.p = r.PointAtParameter(rec.t);
  rec.normal = normalize(rec.p - center);
  rec.normal = vec3(0, 0, 1);  
  
  // Calculate Normal  
  /*
  vec3 pc = rec.p - center;  
  vec3 calNormal;
  
  if (abs(pc.x) >= 1.0 && abs(pc.y) < 1.0 &&  abs(pc.z) < 1.0)
  {
	 if (pc.x < 0) rec.normal = vec3(-1, 0, 0);
	 else if (pc.x > 0) rec.normal = vec3(1, 0, 0);
	 return true; 
  }  
  if (abs(pc.y) >= 1.0 && abs(pc.x) < 1.0 &&  abs(pc.z) < 1.0)
  {
	if (pc.y < 0) rec.normal = vec3(0, -1, 0);
	else if (pc.y > 0) rec.normal = vec3(0, 1, 0);
	 return true; 
  }
  if (abs(pc.z) >= 1.0 && abs(pc.x) < 1.0 &&  abs(pc.y) < 1.0)
  {
	 if (pc.z < 0) rec.normal = vec3(0, 0, -1);
	 else if (pc.z > 0) rec.normal = vec3(0, 0, 1);
	 return true;
  }
  */
  return true; 
}

bool Triangle::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {

	rec.t = tMin;
	rec.p = vec3(0,0,0);
	rec.normal = vec3(0,0,0);
	rec.uv = vec2(0,0);
	rec.albedo = albedo;
	rec.material = material;
	
	// find vectors for two edges sharing vert0
    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;
    
    // begin calculating determinant - also used to calculate U parameter
    float3 pvec = cross(r.direction, edge2);
    
    // if determinant is near zero, ray lies in plane of triangle
    float det = dot(edge1, pvec);
    
    // use no culling
    if (det > -1e-8 && det < 1e-8)
        return false;

    float inv_det = 1.0f / det;
    
    // calculate distance from vert0 to ray origin
    float3 tvec = r.origin - v0;
    
    // calculate U parameter and test bounds
    float u = dot(tvec, pvec) * inv_det;
    if (u < 0.0 || u > 1.0f)
        return false;
    
    // prepare to test V parameter
    float3 qvec = cross(tvec, edge1);
    
    // calculate V parameter and test bounds
    float v = dot(r.direction, qvec) * inv_det;
    if (v < 0.0 || u + v > 1.0f)
        return false;
    
    // calculate t, ray intersects triangle
    float t = dot(edge2, qvec) * inv_det;
    
	/*
	vec3 v0v1 = v1 - v0; 
    vec3 v0v2 = v2 - v0; 
    vec3 pvec = cross(r.direction, v0v2); 
    float det = dot(v0v1, pvec);

    // ray and triangle are parallel if det is close to 0
    if (abs(det) < 0.0001) return false; 

    float invDet = 1 / det; 
 
    vec3 tvec = r.origin - v0; 
    float u = dot(tvec, pvec)* invDet; 
    if (u < 0 || u > 1) return false; 
 
    vec3 qvec = cross(tvec, v0v1);
    float v = dot(r.direction, pvec) * invDet; 
    if (v < 0 || u + v > 1) return false; 
 
    float t = dot(v0v2, qvec) * invDet; 
   if (t <= 0) return false; 
   */
	rec.t = t;
	rec.p = r.PointAtParameter(rec.t);
	rec.normal = normal;

    return true; // this ray hits the triangle 
}
